Detects certificates issued by a CA in either the Machine's or User's personal store that are expired, or near expiry.

Specify the CA by changing the value for $strMatch in the detection script. Specify 0 for $expiringDays to find expired certificates, or specify another number of days to find certificates near expiry.

Remediates by raising a toast notification to the user.

Specify the $Title and $msgText values with the message title and text you want users to see.

Notifies users of expired certificates that might need to be renewed.

Run the script using the logged-on credentials: Yes