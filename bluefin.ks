ostreecontainer --url="ghcr.io/ublue-os/bluefin:38" --no-signature-verification
url --url="https://download.fedoraproject.org/pub/fedora/linux/development/38/Everything/x86_64/os/" 

%post --logfile=/root/ks-post.log --erroronfail
%end
