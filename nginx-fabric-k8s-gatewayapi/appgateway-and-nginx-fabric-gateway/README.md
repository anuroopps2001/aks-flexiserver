1. The Request (Port 80)
You ran curl -L http://74.225.196.74.

Laptop: "Hey, 74.225.196.74, give me the page on Port 80."

App Gateway: "I have a listener for Port 80! I'll pass this to NGINX."

NGINX: "Wait, my rule says use HTTPS. Here is a 301 Redirect to https://app1.local."

2. The Follow (-L)
Your curl command sees that 301 and says, "Understood, I will now follow that link."

Laptop: "Okay, now I'm trying to connect to 74.225.196.74 on Port 443 (HTTPS)."

3. The Brick Wall
This is where the failure happened:

The NSG: Even if you opened the port in the Network Security Group, the Application Gateway itself had no "Receptionist" (Listener) waiting on Port 443.

The Result: The App Gateway literally ignored the packet. From your laptop's perspective, it looked like the server disappeared.
