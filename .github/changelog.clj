#!/usr/bin/env bb

(ns changelog
  (:require [cheshire.core :as json]
            [clojure.string :as str]
            [babashka.process :refer [shell]]
            [clojure.set :as set]
            [selmer.parser :as selmer]))

;; ----------------------------------------------------------------------------
;; Configuration
;; ----------------------------------------------------------------------------

(def registry "ghcr.io/ublue-os/")
(def cosign-key
  "https://raw.githubusercontent.com/ublue-os/aurora/refs/heads/main/cosign.pub")

(def default-images
  ["bluefin" "bluefin-dx"])

(def retries 3)
(def retry-wait-ms 2000)

;; ----------------------------------------------------------------------------
;; Utilities
;; ----------------------------------------------------------------------------

(defn run-cmd [cmd]
  (let [{:keys [out err exit]}
        (apply shell {:out :string :err :string} cmd)]
    (if (zero? exit)
      out
      (throw (ex-info "Command failed"
                      {:cmd cmd :err err :exit exit})))))

(defn retry [n f]
  (loop [attempt 1]
    (let [result
          (try
            {:ok (f)}
            (catch Exception e
              {:error e}))]
      (if-let [value (:ok result)]
        value
        (if (< attempt n)
          (do
            (Thread/sleep retry-wait-ms)
            (recur (inc attempt)))
          (throw (:error result)))))))

;; ----------------------------------------------------------------------------
;; SBOM Fetching
;; ----------------------------------------------------------------------------

(defn fetch-manifest [image tag]
  (retry retries
         #(-> (run-cmd ["skopeo" "inspect"
                        (str "docker://" registry image ":" tag)])
              (json/parse-string true))))

(defn get-digest [image tag]
  (:Digest (fetch-manifest image tag)))

(defn extract-payload [s]
  (second (re-find #"\"payload\":\"([^\"]+)\"" s)))

(defn fetch-sbom [image digest]
  (retry retries
    #(let [cmd ["cosign" "verify-attestation"
                "--type" "spdxjson"
                "--key" cosign-key
                (str registry image "@" digest)]
           raw (run-cmd cmd)
           payload-b64 (extract-payload raw)
           decoder (java.util.Base64/getDecoder)
           bytes (.decode decoder payload-b64)
           payload-json (json/parse-string (String. bytes) true)]
       (:predicate payload-json))))

;; ----------------------------------------------------------------------------
;; Package Extraction
;; ----------------------------------------------------------------------------

(def epoch-pattern #"^\d+:")
(def fedora-pattern #"\.fc\d+")

(defn normalize-version [v]
  (-> v
      (str/replace epoch-pattern "")
      (str/replace fedora-pattern "")))

(defn parse-packages [sbom]
  (let [pkg-map (->> (:artifacts sbom)
                     (filter #(= "rpm" (:type %)))
                     (reduce (fn [m {:keys [name version]}]
                               (if (and name version)
                                 (assoc m name (normalize-version version))
                                 m))
                             {}))]
    (into (sorted-map) pkg-map)))

(defn fetch-packages [image tag]
  (let [digest (get-digest image tag)
        sbom   (fetch-sbom image digest)]
    (parse-packages sbom)))

(defn build-release [images tag]
  (into (sorted-map)
        (for [img images]
          [img {:packages (fetch-packages img tag)}])))

;; ----------------------------------------------------------------------------
;; Diff Logic
;; ----------------------------------------------------------------------------

(defn diff-packages [prev curr]
  (let [prev-keys (set (keys prev))
        curr-keys (set (keys curr))]
    (into (sorted-map)
          {:added   (into (sorted-map) (select-keys curr (set/difference curr-keys prev-keys)))
           :removed (into (sorted-map) (select-keys prev (set/difference prev-keys curr-keys)))
           :changed (into (sorted-map)
                          (for [k (set/intersection prev-keys curr-keys)
                                :when (not= (prev k) (curr k))]
                            [k {:from (prev k) :to (curr k)}]))})))

(defn diff-images [prev-release curr-release]
  (into (sorted-map)
        (for [[img {:keys [packages]}] curr-release]
          (let [prev-pkgs (get-in prev-release [img :packages] {})]
            [img (diff-packages prev-pkgs packages)]))))

(defn common-packages [release]
  (apply set/intersection
         (map (comp set keys :packages val) release)))

;; ----------------------------------------------------------------------------
;; Git Commit Extraction
;; ----------------------------------------------------------------------------

(defn fetch-commits [prev-tag curr-tag]
  (let [out (run-cmd ["git" "log" "--pretty=format:%H;%s;%an" (str prev-tag ".." curr-tag)])]
    (->> (str/split-lines out)
         (map (fn [line]
                (let [[hash subject author] (str/split line #";")]
                  {:hash hash :subject subject :author author})))
         vec)))

;; ----------------------------------------------------------------------------
;; Selmer Markdown Template
;; ----------------------------------------------------------------------------

(def changelog-template "
# {{curr_tag}}: Stable Release

This is an automatically generated changelog for release `{{curr_tag}}`.

From previous version `{{prev_tag}}` there have been the following changes. **One package per new version shown.**

{% for img, pkg_diff in diff %}
### {{img}} Packages
| Name | Version |
| --- | --- |
{% for name, data in pkg_diff.added %}| ✨ {{name}} | {{data}} |{% endfor %}
{% for name, data in pkg_diff.removed %}| ❌ {{name}} | {{data}} |{% endfor %}
{% for name, data in pkg_diff.changed %}| 🔄 {{name}} | {{data.from}} ➡️ {{data.to}} |{% endfor %}
{% endfor %}

{% if commits %}
### Commits
| Hash | Subject | Author |
| --- | --- | --- |
{% for commit in commits %}| **[{{commit.hash}}](https://github.com/ublue-os/bluefin/commit/{{commit.hash}})** | {{commit.subject}} | {{commit.author}} |{% endfor %}
{% endif %}
")

(defn render-changelog
  [{:keys [prev-tag curr-tag diff commits]}]
  (selmer/render changelog-template
                 {:prev_tag prev-tag
                  :curr_tag curr-tag
                  :diff diff
                  :commits commits}))

;; ----------------------------------------------------------------------------
;; Public API
;; ----------------------------------------------------------------------------

(defn build-release-data
  [{:keys [images prev-tag curr-tag]
    :or {images default-images}}]
  (let [prev (build-release images prev-tag)
        curr (build-release images curr-tag)
        diff (diff-images prev curr)
        commits (fetch-commits prev-tag curr-tag)]
    {:prev-tag prev-tag
     :curr-tag curr-tag
     :images images
     :releases {:previous prev :current curr}
     :common-packages (common-packages curr)
     :diff diff
     :commits commits}))

;; ----------------------------------------------------------------------------
;; CLI
;; ----------------------------------------------------------------------------

(defn -main [& args]
  (let [[prev-tag curr-tag out-file] args
        out-file (or out-file "changelog.md")]
    (when (or (nil? prev-tag) (nil? curr-tag))
      (println "Usage: bb changelog.clj <prev-tag> <curr-tag> [output-file]")
      (System/exit 1))
    (let [release-data (build-release-data {:prev-tag prev-tag
                                            :curr-tag curr-tag})
          rendered-md  (render-changelog release-data)]
      ;; Print Markdown to stdout
      (println rendered-md)
      ;; Write Markdown to file
      (spit out-file rendered-md)
      (println "\n✅ Changelog written to" out-file))))

(apply -main *command-line-args*)
