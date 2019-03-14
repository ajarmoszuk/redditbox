# redditbox.us
View Reddit on SSH or Telnet.

This project will allow you to view Reddit in the CLI via an application called [RTV](https://github.com/michael-lazar/rtv).


To run this container, use the following (make sure you generate a RSA private key beforehand):
```bash
docker run -it -d --name redditbox -p 80:80 -p 22:22 -p 23:23 -p 443:443 -v <rsa_key_location>/id_rsa:/app/id_rsa:ro falkenssmaze/redditbox
```


RTV (Reddit Terminal Viewer) is developed by Michael Lazar, Redditbox.us is a independent project and has no official affiliation with RTV or Michael Lazar.
