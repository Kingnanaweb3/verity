#!/usr/bin/env bash
set -e

mkdir -p web

# Copy the hero image from Downloads into the repo so the page can reference it
cp ~/Downloads/52BB1243-5BD2-4EA2-949A-4833C507E79F.PNG web/hero.jpg
echo "copied hero image into web/hero.jpg"

cat > web/style.css << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=Inter+Tight:wght@400;500&family=DM+Sans:wght@300;400;500&family=Roboto+Mono:wght@400&display=swap');

:root{
  --bg:#000000;
  --ink:#ffffff;
  --muted:rgba(255,255,255,.62);
  --faint:rgba(255,255,255,.38);
  --line:rgba(255,255,255,.14);
  --surface:rgba(255,255,255,.035);
  --surface-hi:rgba(255,255,255,.07);
  --accent:#6C5CE7;
  --accent-soft:rgba(108,92,231,.18);

  --h:'Inter Tight',-apple-system,sans-serif;
  --b:'DM Sans',-apple-system,sans-serif;
  --m:'Roboto Mono',ui-monospace,monospace;
}

*{box-sizing:border-box}
html,body{margin:0;padding:0;overflow-x:clip}
body{
  background:var(--bg);
  color:var(--ink);
  font-family:var(--b);
  font-weight:300;
  -webkit-font-smoothing:antialiased;
}

body::after{
  content:'';position:fixed;inset:0;pointer-events:none;z-index:50;opacity:.14;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23n)' opacity='.5'/%3E%3C/svg%3E");
}

.pill{
  display:inline-flex;align-items:center;gap:7px;border-radius:999px;
  padding:12px 24px;font-family:var(--b);font-weight:500;font-size:14px;
  text-decoration:none;border:1px solid var(--line);color:var(--ink);
  background:rgba(255,255,255,.05);backdrop-filter:blur(12px);
  transition:transform 180ms,background 180ms;cursor:pointer;
}
.pill:hover{transform:translateY(-1px);background:rgba(255,255,255,.1)}
.pill.primary{background:#fff;color:#000;border-color:transparent}
.pill.primary:hover{background:#f0f0f0}

/* ---- NAV ---- */
.nav{
  position:fixed;top:0;left:0;right:0;z-index:40;
  display:flex;align-items:center;justify-content:space-between;
  padding:22px clamp(24px,4vw,56px);
  border-bottom:1px solid rgba(255,255,255,.08);
  background:linear-gradient(to bottom, rgba(0,0,0,.55), transparent);
}
.nav-logo{
  display:flex;align-items:center;gap:9px;
  font-family:var(--h);font-weight:500;font-size:17px;color:var(--ink);
  text-decoration:none;
}
.nav-logo svg{color:var(--accent)}
.nav-links{
  display:flex;gap:34px;list-style:none;margin:0;padding:0;
  font-size:14px;color:var(--muted);
}
.nav-links a{color:inherit;text-decoration:none;transition:color 180ms}
.nav-links a:hover{color:var(--ink)}
@media (max-width:860px){ .nav-links{display:none} }

/* ---- HERO ---- */
.hero{
  position:relative;
  min-height:100svh;
  display:flex;flex-direction:column;justify-content:flex-end;
  align-items:center;text-align:center;
  padding:0 clamp(24px,6vw,64px) clamp(56px,7vw,96px);
  background-image:
    linear-gradient(to bottom, rgba(0,0,0,0) 0%, rgba(0,0,0,.35) 55%, rgba(0,0,0,.94) 88%, #000 100%),
    url('hero.jpg');
  background-size:cover;
  background-position:center 30%;
}
.hero h1{
  font-family:var(--h);font-weight:500;
  font-size:clamp(34px,8.6vw,76px);
  line-height:1.04;letter-spacing:-.034em;
  max-width:20ch;margin:0 0 22px;
  text-wrap:balance;
}
.hero h1 .muted{color:var(--faint)}
.hero .lead{
  font-family:var(--b);font-weight:300;
  font-size:clamp(15px,1.35vw,16.5px);line-height:1.70;
  color:var(--muted);
  max-width:min(100%,52ch);
  margin:0 0 34px;
}
.hero .pill{margin-top:4px}

@media (max-width:700px){
  .hero{background-position:center 20%}
}
EOF
echo "wrote web/style.css"

cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Verity — Verified. Not just claimed.</title>
<link rel="stylesheet" href="style.css">
</head>
<body>

<nav class="nav">
  <a href="#" class="nav-logo">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
    Verity
  </a>
  <ul class="nav-links">
    <li><a href="#how-it-works">How it works</a></li>
    <li><a href="#reliability">Reliability</a></li>
    <li><a href="#findings">Findings</a></li>
  </ul>
  <a href="https://github.com/Kingnanaweb3/verity" class="pill">View the repo</a>
</nav>

<section class="hero">
  <h1>Verified.<br><span class="muted">Not just claimed.</span></h1>
  <p class="lead">
    Verity checks every claim your agent makes against what actually happened
    in Slack and Linear, before you find out the hard way.
  </p>
  <a href="#findings" class="pill primary">See it running ↗</a>
</section>

</body>
</html>
EOF
echo "wrote web/index.html"
