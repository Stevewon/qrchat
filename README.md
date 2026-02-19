# QRChat Website

Official website for QRChat - QR Code Based Secure Chat App

## 🌐 Live Site
- Production: https://qrchat.io
- GitHub Pages: https://stevewon.github.io/qrchat

## 📁 Structure

```
qrchat-website/
├── index.html          # Main landing page
├── privacy.html        # Privacy policy
├── terms.html          # Terms of service
├── download.html       # Download page
└── README.md          # This file
```

## 🎨 Features

- **Responsive Design**: Works on all devices
- **Modern UI**: Clean and professional design
- **App Store Buttons**: Google Play and App Store ready
- **Feature Showcase**: 6 key features highlighted
- **How It Works**: Step-by-step guide
- **Social Links**: GitHub integration

## 🚀 Deployment

### GitHub Pages
1. Push to GitHub repository
2. Enable GitHub Pages in repository settings
3. Set source to `main` branch

### Custom Domain (qrchat.io)
1. Add CNAME file with `qrchat.io`
2. Configure DNS:
   ```
   Type: A
   Name: @
   Value: 185.199.108.153
          185.199.109.153
          185.199.110.153
          185.199.111.153

   Type: CNAME
   Name: www
   Value: stevewon.github.io
   ```

### Cloudflare Pages
1. Connect GitHub repository
2. Build settings:
   - Build command: (none)
   - Build output directory: `/`
   - Root directory: `qrchat-website`
3. Add custom domain: qrchat.io

## 📱 App Store Links

Update these placeholders when apps are published:

- **Google Play**: `#` → `https://play.google.com/store/apps/details?id=com.qrchat.app`
- **App Store**: `#` → `https://apps.apple.com/app/qrchat/id123456789`

## 🔧 Customization

### Colors
Edit CSS variables in `index.html`:
```css
:root {
    --primary: #667eea;
    --secondary: #764ba2;
    --accent: #f093fb;
}
```

### Content
- Update feature descriptions
- Add more screenshots
- Modify download links

## 📊 Analytics

Add Google Analytics or other tracking:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_TRACKING_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_TRACKING_ID');
</script>
```

## 🔗 Links

- **GitHub**: https://github.com/Stevewon/qrchat
- **Latest Release**: https://github.com/Stevewon/qrchat/releases/latest
- **Source Backup**: Available on request

## 📄 License

Copyright © 2026 QRChat. All rights reserved.

## 👤 Developer

- **Name**: Stevewon
- **GitHub**: https://github.com/Stevewon
- **Project**: QRChat v1.0.100

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-19  
**Status**: Production Ready ✅
