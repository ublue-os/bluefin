ostreecontainer --url="ghcr.io/sisus198/tblue-nvidia:38" --no-signature-verification
url --url="https://download.fedoraproject.org/pub/fedora/linux/development/38/Everything/x86_64/os/" 

%post --logfile=/root/ks-post.log --erroronfail
%end
