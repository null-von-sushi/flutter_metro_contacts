Contacts app written in the Windows Phone 8.1 style, but for Android


- Windows Phone 8.1 metro UI style
- Optionally can take the accent color of METROV Launcher (no affiliation, 3rd party app, I just think it's the best WP8.1 style launcher there is as of yet)
- Can filter contacts based on account and group
- Dedicated groups tab so that even if you only show personal contacts, you can still see your work contacts if you REALLY need
- Automatically sets any contact that is named 'Me' (or 我, or maybe even the concept of 'me' in some other languages I forgot) as the 'Me' tile 
- Optionally highlights and displays nicknames you set for contacts
- Sorts Chinese names according to Pinyin, instead of sorting them all under `#`
- Shows a little birthday cake on the contat's page if it's their birthday
- overrides the accent color per-contact if the notes of a contact has 'favorite color: red' or something similar in it. I think hex codes might also work.
- Supprots _some_ username for modern messaging. As a rule, they should be added as URLs that perform some action. For example, `https://t.me/username` for telegram, or `https://signal.me/#p/+007123456789` for signal etc. For Wechat there is `weixin://dl/chat?username` which doesn't actually work because WeChat is cancer and wouldn't survive a second in a free market, but for your convenience we still try to support it in some way. What that means in practice is that for wechat usernames you just get the option to copy the username, and wechat itself will be opened. You need to paste it yourself to add a new contact or whatever.
- Supports favorites that actually are synced with the rest of the system ('starred' contacts on android)
- Built using flutter 
- uses [wp_pivot_flutter](https://github.com/Chinmay-KB/wp_pivot_flutter) for a lot of UI components

It works, and I like to think it's polished enough to use as your main contacts app (I mean, I do) but don't expect too many features. I probably won't add more features but maybe consider adding translations or fixing bugs. 

## Screenshots
<img width="720" height="780" alt="animated screenshot" src="https://github.com/user-attachments/assets/b0494f17-d6fe-4778-ac36-a18ea4b9df19" />
