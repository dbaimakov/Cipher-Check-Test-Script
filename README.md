# Cipher-Check-Test-Script
This Bash script tests SSL/TLS cipher support for a given server endpoint. It attempts a handshake with each cipher, reports whether it was accepted or rejected, and summarizes the results.

🔍 Overview
This Bash script tests SSL/TLS cipher support for a given server endpoint. It attempts a handshake with each cipher, reports whether it was accepted or rejected, and summarizes the results.
The script is useful for:
•	Auditing servers for legacy/weak cipher acceptance
•	Validating TLS configurations during security assessments
•	Quickly checking compliance with organizational cipher policies
________________________________________
🚀 Features
•	Accepts server, port, URL, cookie, and optional cipher file via CLI arguments
•	Uses a default cipher list if no file is provided
•	For each cipher:
o	Attempts a curl connection
o	Reports accepted vs rejected
o	Notes protocol and negotiated cipher when successful
•	Provides a final summary of results
________________________________________
📦 Requirements
•	Bash (Linux/macOS or WSL on Windows)
•	curl with TLS support (OpenSSL/Schannel/etc.)
Optional:
•	A text file (weak_ciphers.txt) with one cipher suite per line

Purpose
Iterate through a list of TLS cipher suites, attempt a handshake to a target URL with curl, and report which ciphers are accepted vs rejected. Optional cookie support enables testing authenticated paths.

🖥️ Usage
./cipher_test.sh -s <server> -p <port> -u <url> [-c <cookie>] [-f <cipher_file>]

📊 Sample Output
<img width="975" height="691" alt="image" src="https://github.com/user-attachments/assets/32d58b40-98a8-4749-a2b4-2c9b49b72254" />
