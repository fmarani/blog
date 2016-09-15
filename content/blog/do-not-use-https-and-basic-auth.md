+++
date = "2016-09-15T12:23:07+02:00"
title = "Do not use HTTPS and basic auth"
tags = ["security"]

+++

Security is a difficult topic, the discipline is very "deep", therefore it is easy to make mistakes if you do not dig deep enough. Unfortunately many people misjudge perceived security with real security, on the basis of "it makes sense".

HTTPS is a wonderful protocol, it gives you encryption therefore you cannot see what is going on at L7 (urls, http headers, http verbs, app data). This level of obscurity may be enough for simple apps. The fact that your app knows your private REST api structure is already a (weak) client authentication proof. **Basic auth does not give you any extra security on top of that**, because if you can read the REST urls (with a MITM attack), you can read the password hash, and if you know the password hash, you can send requests as the original client. You can reuse the hash to reauthenticate yourself.

In most cases, it is enough for your app to **verify the server SSL certificate**. When you do that, it gets almost impossible to hack the connection and read data from it.

If you want some extra security, you could:

1. Introduce API keys and passwords for app users. It is going to be application dependent, so up to you to build the verification for this. **This is not a strong authentication model**, but because they are User-specific, if they are compromised, these credentials can be easily revoked and reset. Many SaaS use this method, because it is very easy to deploy at scale and to understand.
2. Use HTTP Digest auth, or something with a randomized pre-shared nonce. Differently from all the previous ones, this is not vulnerable to replay attacks, therefore it is more secure.
3. Have some mechanism to sign HTTP requests. This is not an authentication mechanism, but it protects against data tampering. If an hacker sees that you are protected against replay attacks, the next logical step is modify existing requests on the fly. If the request is signed, this will be much harder.
4. Use HTTPS Client certificates, that the server authenticates. This is a bit harder to put in place and theoretically offers maximum protection.

Security is not an immutable thing in time. Things that were secure 5 years ago might not be considered secure today. Security is also not an absolute, there is no 100% secure. Your only option is to defend yourself down every level of your stack, hoping that whoever wants to hack you either loses interest in you or runs out of hacking ideas.

All the above options can be used in combination, because they offer different benefits. Evaluating the right combination is up to you. This is a run-through all possible options, focusing only on security at transport level. There is a lot more to say about security of the device. If an attacker is able to get access to the application code, the surface of attack becomes bigger.
