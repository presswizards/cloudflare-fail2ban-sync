# cloudflare-fail2ban-sync
Use this lil script to sync fail2ban's ban and unban IPs to Cloudflare across all sites in all accounts you have access to.

<p/>
<a href="https://www.buymeacoffee.com/robwpdev" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a><br>
If this script saves you time, helps your clients, or helps you do better work, I’d appreciate it.
</p>

## The Cloudflare / fail2ban Problem
Fail2Ban is commonly used to block malicious IPs based on bad behavior detected in server logs, such as website request logs or failed SSH logins.
The issue is fail2ban blocks bad behavior and bad bots sending requests to website logs that are usually from the Real-IP header of the request, triggering fail2ban to block that IP at the iptables firewall level, but the firewall only sees the Cloudflare IP, so the block is useless. fail2ban works for non-website logs like failed SSH logins etc, but those IPs are not blocked at the Cloudlfare level and they should be, to protect the websites from other malicious requests from those same IPs.

## How This Script Solves the Problem
This script resolves both issues by using Cloudflare's API to block or unblock IPs directly at the account level for all sites associated with your Cloudflare account. Triggered by Fail2Ban’s iptables actions, the script ensures that malicious IPs are blocked before they ever reach your server—across all accounts that your global Cloudflare API key has access to.

The result: effective blocking at the Cloudflare level for all bad IPs, whether they are trying to attack your websites or SSH endpoints, enhancing your security by preventing attacks before they hit your infrastructure.

## Useage

- First, download and save the cloudflare-fail2ban-sync.sh file to your server, I just put mine in /root/.
- Be sure to chmod 700 the file so it's executable and no one else can read it.
- Edit the script and add your Cloudflare Global API key and the email address associated with that key:

```
 # Cloudflare Global API Key and Email
CF_API_KEY="bzsl3-not-real-replace-me-bc50zl3954io2e4"
CF_EMAIL="support@yourdomain.com"
```

- Add this script to your fail2ban iptables.conf file, so it triggers the ban or unban of the IP it's trying to block:

```$ sudo nano /etc/fail2ban/action.d/iptables.conf```

Find the actionban line, and add this script right under it, like so:

```
   actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
               /root/cloudflare-fail2ban-sync.sh ban <ip>
```

Do the same for the actionunban line:

```
   actionunban = <iptables> -D f2b-<name> -s <ip> -j <blocktype>
                 /root/cloudflare-fail2ban-sync.sh unban <ip>
```            
- Save the file, reload fail2ban:

 ```$ sudo service fail2ban reload```

- Optionally, try banning an IP and view it in Cloudflare:

 ```$ sudo fail2ban-client set ssh banip 192.168.0.1```

Wait 15-30 seconds and then in Cloudflare, go to the domain > Security > Security rules > click on IP Access Rules under Custom Rules section

- Then unban it, and reload the IP Access Rules page after 15-30 seconds, and it should be deleted, like magic!

### Note: Cloudfare's web UI seems to display the IP Access Rules inconsistently, showing only 1 rule, or 10, etc... reloading seems to help. It also seems to display only 100 maximum, even though via the API I've verified there are more than 100 rules, so the new ones are at the top. You can add additional rules using their Web UI, but editing is buggy, it displays a 404 Not Found, maybe because the rules are being cached or updated.

## Advanced

Edit the notes line to customize the rule description displayed in Cloudflare:

```   "notes": "Blocked by Fail2Ban (All Sites)"```

You could change it to:

```   "notes": "Blocked by GreatHosting Fail2Ban on Server92 (All Sites)"```

That way you'll know which server it came from etc.

## Please Support My Dev Efforts 

<p/>
<a href="https://www.buymeacoffee.com/robwpdev" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a><br>
If this script saves you time, helps your clients, or helps you do better work, I’d appreciate it.
</p>
