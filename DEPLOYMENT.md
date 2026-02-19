# QRChat Website Deployment Guide

## 🌐 Domain: qrchat.io

This guide will help you deploy the QRChat website to qrchat.io domain.

---

## 📋 Prerequisites

- Domain: qrchat.io (already owned)
- GitHub account: Stevewon
- Repository: https://github.com/Stevewon/qrchat

---

## 🚀 Deployment Options

### Option 1: GitHub Pages (Recommended)

#### Step 1: Push Website to GitHub

```bash
# Navigate to repository
cd /home/user/webapp

# Create website branch or directory
git checkout -b gh-pages
# OR create a 'docs' folder in main branch

# Copy website files
cp -r /home/user/qrchat-website/* ./docs/

# Commit and push
git add .
git commit -m "Add qrchat.io website"
git push origin gh-pages
```

#### Step 2: Enable GitHub Pages

1. Go to repository settings: https://github.com/Stevewon/qrchat/settings/pages
2. Source: Select `gh-pages` branch (or `main` branch with `/docs` folder)
3. Custom domain: Enter `qrchat.io`
4. Check "Enforce HTTPS"
5. Save

#### Step 3: Configure DNS (at your domain registrar)

Add these DNS records:

```
Type: A
Name: @
Value: 185.199.108.153
Value: 185.199.109.153
Value: 185.199.110.153
Value: 185.199.111.153

Type: CNAME
Name: www
Value: stevewon.github.io
```

Wait 24-48 hours for DNS propagation.

---

### Option 2: Cloudflare Pages

#### Step 1: Connect Repository

1. Go to Cloudflare Pages: https://pages.cloudflare.com/
2. Click "Create a project"
3. Connect GitHub account
4. Select repository: `Stevewon/qrchat`

#### Step 2: Build Settings

```
Framework preset: None
Build command: (leave empty)
Build output directory: /
Root directory: qrchat-website
```

#### Step 3: Add Custom Domain

1. After deployment, go to project settings
2. Custom domains → Add custom domain
3. Enter: `qrchat.io`
4. Cloudflare will automatically configure DNS

---

### Option 3: Netlify

#### Step 1: Deploy

1. Go to https://app.netlify.com/
2. Click "Add new site" → "Import an existing project"
3. Connect GitHub repository
4. Configure:
   ```
   Base directory: qrchat-website
   Build command: (leave empty)
   Publish directory: ./
   ```

#### Step 2: Custom Domain

1. Site settings → Domain management
2. Add custom domain: `qrchat.io`
3. Follow DNS configuration instructions

---

## 📱 Update App Store Links

When apps are published, update these links in `index.html`:

### Google Play

Replace:
```html
<a href="#" class="download-btn android">
```

With:
```html
<a href="https://play.google.com/store/apps/details?id=com.qrchat.app" class="download-btn android">
```

### App Store

Replace:
```html
<a href="#" class="download-btn ios">
```

With:
```html
<a href="https://apps.apple.com/app/qrchat/id123456789" class="download-btn ios">
```

---

## 🔧 Testing Before Deployment

Test locally:

```bash
cd /home/user/qrchat-website
python3 -m http.server 8000
# Open: http://localhost:8000
```

---

## ✅ Deployment Checklist

- [ ] Website files ready
- [ ] CNAME file created
- [ ] DNS records configured
- [ ] GitHub Pages enabled
- [ ] Custom domain added
- [ ] HTTPS enforced
- [ ] Privacy policy complete
- [ ] Terms of service complete
- [ ] Download links updated
- [ ] Test all pages
- [ ] Mobile responsive check
- [ ] SEO meta tags added

---

## 📊 Post-Deployment

### 1. Verify Deployment

```bash
# Check DNS
dig qrchat.io
nslookup qrchat.io

# Check website
curl -I https://qrchat.io
```

### 2. Add Google Analytics (Optional)

Add to `index.html` before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 3. Submit to Search Engines

- Google Search Console: https://search.google.com/search-console
- Bing Webmaster Tools: https://www.bing.com/webmasters

---

## 🔄 Updates

To update website:

```bash
# Make changes
vim index.html

# Commit and push
git add .
git commit -m "Update website"
git push origin gh-pages
```

GitHub Pages/Cloudflare/Netlify will auto-deploy.

---

## 🛠️ Troubleshooting

### DNS Not Resolving

```bash
# Clear DNS cache
sudo systemd-resolve --flush-caches

# Check DNS propagation
https://www.whatsmydns.net/#A/qrchat.io
```

### Certificate Issues

- GitHub Pages: Wait 24 hours for certificate
- Cloudflare: Automatic with Universal SSL
- Netlify: Automatic with Let's Encrypt

### 404 Errors

- Check CNAME file exists
- Verify build output directory
- Check file paths (case-sensitive)

---

## 📞 Support

- GitHub Issues: https://github.com/Stevewon/qrchat/issues
- Developer: Stevewon

---

**Last Updated**: 2026-02-19  
**Status**: Ready for deployment ✅
