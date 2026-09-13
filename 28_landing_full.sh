#!/usr/bin/env bash
set -e

# ============ APPEND TO style.css ============
cat >> web/style.css << 'EOF'

/* ============================================================
   SECTIONS
   ============================================================ */
section{position:relative;padding:clamp(96px,10vw,148px) clamp(32px,7vw,96px);}
.eyebrow{
  display:inline-flex;align-items:center;gap:8px;
  font-family:var(--m);font-size:11.5px;letter-spacing:.04em;text-transform:uppercase;
  color:var(--faint);margin-bottom:16px;
}
.eyebrow i{width:6px;height:6px;border-radius:50%;background:var(--accent);display:inline-block}
.section-head{max-width:640px;margin:0 auto 56px;text-align:center}
.section-head h2{
  font-family:var(--h);font-weight:500;font-size:clamp(28px,3.6vw,46px);
  line-height:1.12;letter-spacing:-.032em;margin:0 0 14px;text-wrap:balance;
}
.section-head p{
  font-family:var(--b);font-weight:300;font-size:14.5px;line-height:1.65;
  color:var(--muted);max-width:52ch;margin:0 auto;
}

.reveal{opacity:0;transform:translateY(18px);
  transition:opacity 700ms cubic-bezier(.22,1,.36,1),
             transform 700ms cubic-bezier(.22,1,.36,1);
  transition-delay:var(--d,0ms)}
.reveal.in{opacity:1;transform:none}

@media (prefers-reduced-motion: reduce){
  .reveal{opacity:1!important;transform:none!important;transition:none!important}
}

/* ---- PROOF BAND ---- */
.proof{text-align:center}
.proof-sentence{
  font-family:var(--b);font-weight:300;font-size:15px;color:var(--muted);
  max-width:52ch;margin:0 auto 56px;
}
.proof-grid{
  display:grid;grid-template-columns:repeat(4,1fr);gap:32px;max-width:1160px;margin:0 auto;
}
.proof-num{font-family:var(--m);font-size:clamp(38px,5.6vw,68px);line-height:1;letter-spacing:-.03em;color:var(--ink)}
.proof-cap{font-size:12.5px;color:var(--faint);margin-top:10px;line-height:1.5}
@media (max-width:700px){ .proof-grid{grid-template-columns:repeat(2,1fr);row-gap:44px} }

/* ---- CARD ROW ---- */
.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;max-width:1160px;margin:0 auto}
.card{position:relative;border:1px solid var(--line);border-radius:18px;
  padding:26px;background:var(--surface);backdrop-filter:blur(14px);
  box-shadow:0 30px 60px -30px rgba(0,0,0,.9)}
.card.hl{background:var(--surface-hi)}
.card.hl::before{content:'';position:absolute;inset:0;border-radius:18px;
  pointer-events:none;box-shadow:inset 0 1px 0 rgba(255,255,255,.24)}
.icon-tile{width:46px;height:46px;border-radius:14px;display:flex;align-items:center;justify-content:center;margin-bottom:18px}
.icon-tile.muted{background:rgba(255,255,255,.05);border:1px solid var(--line)}
.icon-tile.accent{background:linear-gradient(140deg,var(--accent),#9B8BF5);
  box-shadow:0 12px 24px -12px rgba(108,92,231,.65), inset 0 1px 0 rgba(255,255,255,.4)}
.card .mono-label{font-family:var(--m);font-size:11px;letter-spacing:.05em;text-transform:uppercase;color:var(--faint);margin-bottom:10px}
.card p{font-size:14.5px;line-height:1.65;color:var(--muted);margin:0}
@media (max-width:1000px){ .cards{grid-template-columns:1fr;max-width:520px} }

/* ---- SPLIT FEATURE ---- */
.split{display:grid;grid-template-columns:1fr 1.05fr;gap:clamp(32px,5vw,72px);
  max-width:1160px;margin:0 auto;align-items:center}
.split-art{position:relative;border-radius:20px;overflow:hidden;aspect-ratio:3/4;
  background-image:url('hero.jpg');background-size:cover;background-position:center 35%;
  filter:saturate(.85) brightness(.8)}
.split-badge{
  position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);
  width:64px;height:64px;border-radius:18px;
  background:linear-gradient(150deg,rgba(28,30,38,.92),rgba(18,20,27,.86));
  border:1px solid rgba(255,255,255,.16);
  box-shadow:0 18px 44px -18px rgba(108,92,231,.55), inset 0 1px 0 rgba(255,255,255,.14);
  display:flex;align-items:center;justify-content:center;color:var(--accent-2,#9B8BF5);
}
.split-copy .lead{font-size:16px;line-height:1.7;color:var(--ink);font-weight:300;margin:0 0 28px;max-width:46ch}
.split-points{display:flex;flex-direction:column;gap:20px;margin-bottom:32px}
.split-point{display:flex;gap:14px;align-items:flex-start}
.split-point svg{flex-shrink:0;color:var(--accent);margin-top:2px}
.split-point div b{display:block;font-weight:500;font-size:14.5px;margin-bottom:3px;color:var(--ink)}
.split-point div span{font-size:13.5px;color:var(--muted);line-height:1.55}
@media (max-width:860px){ .split{grid-template-columns:1fr} .split-art{aspect-ratio:16/10} }

/* ---- PRODUCT SHOT (real terminal recreation) ---- */
.termshot{max-width:900px;margin:0 auto;border-radius:14px;overflow:hidden;
  border:1px solid var(--line);background:rgba(0,0,0,.55);
  box-shadow:0 40px 90px -40px rgba(0,0,0,.9)}
.termshot-bar{display:flex;gap:7px;padding:14px 16px;border-bottom:1px solid var(--line)}
.termshot-bar span{width:11px;height:11px;border-radius:50%;background:rgba(255,255,255,.15)}
.termshot pre{margin:0;padding:26px;font-family:var(--m);font-size:12.5px;line-height:1.7;
  color:var(--muted);overflow-x:auto;white-space:pre}
.termshot .ok{color:#4ade80}
.termshot .fail{color:#f87171}
.termshot .skip{color:var(--faint)}

/* ---- FULL-BLEED FINDINGS ---- */
.findings-img{
  height:56vh;min-height:340px;
  background-image:
    linear-gradient(to bottom, rgba(0,0,0,.2) 0%, #000 100%),
    url('hero.jpg');
  background-size:cover;background-position:center 25%;
  filter:saturate(.7) brightness(.7);
}
.findings-grid{
  display:grid;grid-template-columns:repeat(4,1fr);gap:32px;max-width:1160px;margin:-40px auto 0;position:relative;
}
.finding{padding:0 4px}
.finding .num{font-family:var(--m);font-size:clamp(28px,3vw,38px);color:var(--ink);margin-bottom:12px;display:block}
.finding .claim{font-weight:500;font-size:15px;margin-bottom:8px;color:var(--ink)}
.finding .desc{font-size:13px;line-height:1.6;color:var(--muted);margin-bottom:14px}
.finding hr{border:none;border-top:1px solid var(--line);margin:0 0 12px}
.finding .so{font-size:12.5px;color:var(--faint);line-height:1.5;font-style:normal}
@media (max-width:1000px){ .findings-grid{grid-template-columns:1fr;max-width:520px;gap:36px} }

/* ---- FAQ ---- */
.faq-wrap{display:grid;grid-template-columns:1fr 1.15fr;gap:56px;max-width:1160px;margin:0 auto}
.faq-wrap h2{font-family:var(--h);font-weight:500;font-size:clamp(28px,3.6vw,46px);line-height:1.12;letter-spacing:-.032em;max-width:16ch}
details{border-bottom:1px solid var(--line);padding:20px 0}
details summary{
  list-style:none;cursor:pointer;display:flex;justify-content:space-between;align-items:center;
  font-family:var(--b);font-weight:500;font-size:15px;color:var(--ink);
}
details summary::-webkit-details-marker{display:none}
details summary .plus{font-size:20px;color:var(--faint);transition:transform 180ms;font-weight:300}
details[open] summary .plus{transform:rotate(45deg)}
details p{font-size:13.5px;line-height:1.65;color:var(--muted);margin:14px 0 0;max-width:60ch}
@media (max-width:860px){ .faq-wrap{grid-template-columns:1fr} }

/* ---- CLOSE ---- */
.close-sec{text-align:center;background:radial-gradient(120% 100% at 50% 0%, var(--accent-soft), transparent 60%)}
.close-sec h2{font-family:var(--h);font-weight:500;font-size:clamp(28px,3.6vw,46px);letter-spacing:-.032em;margin:0 0 14px}
.close-sec p{font-size:14.5px;color:var(--muted);margin:0 0 32px}
.close-ctas{display:flex;gap:14px;justify-content:center;flex-wrap:wrap}

/* ---- FOOTER ---- */
footer{padding:56px clamp(32px,7vw,96px) 40px;border-top:1px solid var(--line)}
.footer-grid{display:grid;grid-template-columns:1.6fr 1fr 1fr;gap:40px;max-width:1160px;margin:0 auto 40px}
.footer-brand{display:flex;align-items:center;gap:9px;font-family:var(--h);font-weight:500;font-size:16px;margin-bottom:12px}
.footer-brand svg{color:var(--accent)}
.footer-blurb{font-size:13px;color:var(--faint);line-height:1.6;max-width:32ch}
.footer-col h4{font-family:var(--m);font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--faint);margin:0 0 16px}
.footer-col a{display:block;font-size:13.5px;color:var(--muted);text-decoration:none;margin-bottom:11px}
.footer-col a:hover{color:var(--ink)}
.footer-fine{max-width:1160px;margin:0 auto;padding-top:28px;border-top:1px solid var(--line)}
.footer-fine p{font-size:12px;line-height:1.65;color:var(--faint);max-width:70ch;margin:0}
@media (max-width:700px){ .footer-grid{grid-template-columns:1fr;gap:28px} }
EOF
echo "appended sections to web/style.css"

# ============ INSERT SECTIONS INTO index.html (before </body>) ============
python3 - << 'PYEOF'
path = "web/index.html"
with open(path) as f:
    content = f.read()

sections = '''
<section class="proof reveal-group">
  <p class="proof-sentence reveal">Every number here is real, pulled from this exact build, not rounded up for a slide.</p>
  <div class="proof-grid">
    <div class="reveal"><div class="proof-num">3</div><div class="proof-cap">External apps connected<br>Airtable, Slack, Linear</div></div>
    <div class="reveal"><div class="proof-num">10/10</div><div class="proof-cap">Eval scenarios passing<br>fully offline, under 6ms</div></div>
    <div class="reveal"><div class="proof-num">12</div><div class="proof-cap">Hard step cap<br>per agent run, enforced in code</div></div>
    <div class="reveal"><div class="proof-num">1</div><div class="proof-cap">Real bug caught<br>by the verifier, live, not staged</div></div>
  </div>
</section>

<section id="how-it-works">
  <div class="eyebrow reveal"><i></i>The tension</div>
  <div class="section-head reveal">
    <h2>An agent can say it finished. That is not the same as it finishing.</h2>
    <p>Tool calls return success codes. A success code is not proof the customer message actually posted, or that the ticket actually updated. Verity treats those as two separate facts, and checks both.</p>
  </div>
  <div class="cards reveal-group">
    <div class="card reveal">
      <div class="icon-tile muted"><svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg></div>
      <div class="mono-label">Step 01 — Flag</div>
      <p>Verity reads every account against its own normal rhythm, not a number that applies to everyone. A customer quiet for thirty days is not stalled if thirty days is normal for them.</p>
    </div>
    <div class="card reveal">
      <div class="icon-tile muted"><svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg></div>
      <div class="mono-label">Step 02 — Draft</div>
      <p>A short, specific reason and a draft outreach message go to Slack. Nothing reaches a real customer without a human approving it first.</p>
    </div>
    <div class="card hl reveal">
      <div class="icon-tile accent"><svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg></div>
      <div class="mono-label">Step 03 — Verify</div>
      <p>After the run, Verity reopens Slack and Linear on its own and checks what is actually there. The agent's claim and the real state have to agree by evidence, not assumption.</p>
    </div>
  </div>
</section>

<section id="reliability">
  <div class="split reveal-group">
    <div class="split-art reveal">
      <div class="split-badge"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg></div>
    </div>
    <div class="split-copy reveal">
      <div class="eyebrow"><i></i>Why this matters</div>
      <p class="lead">The agent's own word is never the last word. A separate piece of code, with its own read access, checks reality after every run.</p>
      <div class="split-points">
        <div class="split-point">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          <div><b>Independent, not self reported</b><span>The agent is never given the tools it would need to check its own work.</span></div>
        </div>
        <div class="split-point">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          <div><b>Idempotent by default</b><span>Running the same account twice never creates a duplicate message or ticket.</span></div>
        </div>
        <div class="split-point">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          <div><b>Fails loud, never silent</b><span>A mismatch between claim and reality is reported plainly, not swallowed.</span></div>
        </div>
      </div>
      <a href="https://github.com/Kingnanaweb3/verity/blob/main/RELIABILITY.md" class="pill">Read the reliability brief ↗</a>
    </div>
  </div>
</section>

<section>
  <div class="section-head reveal">
    <div class="eyebrow" style="justify-content:center"><i></i>Real output</div>
    <h2>What the report actually looks like</h2>
    <p>This is a real verification report from a real run, not a mockup.</p>
  </div>
  <div class="termshot reveal">
    <div class="termshot-bar"><span></span><span></span><span></span></div>
    <pre>============================================================
VERIFICATION REPORT — 2 claims checked, 2 idempotent skips
  Confirmed:  2
  Mismatched: 0
============================================================
  <span class="skip">[SKIP] step 2 (draft_slack_approval): skipped - idempotent hit, no new write this run to verify</span>
  <span class="skip">[SKIP] step 3 (upsert_linear_ticket): skipped - idempotent hit, no new write this run to verify</span>
  <span class="ok">[OK] step 4 (draft_slack_approval): message confirmed present in channel</span>
  <span class="ok">[OK] step 5 (upsert_linear_ticket): ticket confirmed present with matching state</span></pre>
  </div>
</section>

<section id="findings" style="padding-left:0;padding-right:0">
  <div class="section-head reveal">
    <div class="eyebrow" style="justify-content:center"><i></i>Findings</div>
    <h2>What actually broke, and what that proved</h2>
  </div>
  <div class="findings-img reveal"></div>
  <div class="findings-grid">
    <div class="finding reveal">
      <span class="num">54.3%</span>
      <div class="claim">Most agent failures are invisible</div>
      <div class="desc">Published research on multi app agents found over half of failed runs looked complete right up until the final, human facing step.</div>
      <hr><div class="so">So Verity checks the final step independently, every run, not just the steps before it.</div>
    </div>
    <div class="finding reveal">
      <span class="num">1</span>
      <div class="claim">A real bug, not a staged one</div>
      <div class="desc">The agent reported a Slack message had posted. It had not. A missing permission scope was the actual reason.</div>
      <hr><div class="so">So the scope was fixed, then re-verified with the same independent check, not a new claim.</div>
    </div>
    <div class="finding reveal">
      <span class="num">0</span>
      <div class="claim">Duplicate writes across reruns</div>
      <div class="desc">Running the same account twice never creates a second message or a second ticket.</div>
      <hr><div class="so">So a local ledger remembers exactly what already happened, before anything is sent again.</div>
    </div>
    <div class="finding reveal">
      <span class="num">12</span>
      <div class="claim">Hard limit on every run</div>
      <div class="desc">An agent loop with no ceiling can, in principle, run forever on a bad day.</div>
      <hr><div class="so">So every run stops and reports at step twelve, no exceptions, no override.</div>
    </div>
  </div>
</section>

<section>
  <div class="faq-wrap reveal-group">
    <div class="reveal">
      <div class="eyebrow"><i></i>Questions</div>
      <h2>Asked plainly, answered honestly</h2>
    </div>
    <div class="reveal">
      <details>
        <summary>Does Verity verify Airtable too?<span class="plus">+</span></summary>
        <p>No, not yet. The agent only reads from Airtable in this build, it never writes back, so there is nothing on that side to independently confirm. That would be the next system to add.</p>
      </details>
      <details>
        <summary>What happens if Slack and Linear disagree with each other?<span class="plus">+</span></summary>
        <p>Right now they are checked independently. A ticket referencing a message that was later deleted would still pass both checks separately. Cross checking the two against each other is the next reliability layer, not this one.</p>
      </details>
      <details>
        <summary>Can a customer message actually go out without a human?<span class="plus">+</span></summary>
        <p>No. Every outreach is a draft posted to Slack for approval. Nothing reaches a real customer automatically.</p>
      </details>
      <details>
        <summary>What happens if Slack or Linear is down?<span class="plus">+</span></summary>
        <p>Verity retries rate limits and server errors with backoff, gives up cleanly if a service stays down, and reports exactly what got written and what did not, rather than pretending everything worked.</p>
      </details>
      <details>
        <summary>Can someone break it by writing something strange into a customer notes field?<span class="plus">+</span></summary>
        <p>It has been tested against exactly that. Instructions hidden inside account data are treated as data, never as commands, because the list of things the agent is allowed to do is enforced in code, not just requested in a prompt.</p>
      </details>
      <details>
        <summary>Why Groq instead of a larger frontier model?<span class="plus">+</span></summary>
        <p>Speed matters for a step by step agent loop a human is meant to watch and approve close to real time. This tool calling does not need the largest model available, it needs a fast, reliable one.</p>
      </details>
    </div>
  </div>
</section>

<section class="close-sec">
  <h2 class="reveal">Verified. Not just claimed.</h2>
  <p class="reveal">Built in one day, checked against real Slack and Linear accounts, not just against itself.</p>
  <div class="close-ctas reveal">
    <a href="https://github.com/Kingnanaweb3/verity" class="pill primary">View the repo</a>
    <a href="https://github.com/Kingnanaweb3/verity/blob/main/RELIABILITY.md" class="pill">Read the reliability brief ↗</a>
  </div>
</section>

<footer>
  <div class="footer-grid">
    <div>
      <div class="footer-brand">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        Verity
      </div>
      <p class="footer-blurb">An account health agent that checks its own work against Slack and Linear before it calls anything done.</p>
    </div>
    <div class="footer-col">
      <h4>Product</h4>
      <a href="#how-it-works">How it works</a>
      <a href="#reliability">Reliability</a>
      <a href="#findings">Findings</a>
    </div>
    <div class="footer-col">
      <h4>Project</h4>
      <a href="https://github.com/Kingnanaweb3/verity">GitHub repo</a>
      <a href="https://github.com/Kingnanaweb3/verity/blob/main/RELIABILITY.md">Reliability brief</a>
      <a href="https://github.com/Kingnanaweb3/verity/blob/main/README.md">README</a>
    </div>
  </div>
  <div class="footer-fine">
    <p>Verity can post messages to a real Slack workspace and create or update real Linear tickets when run with --apply. Every outreach draft requires a human to approve it before anything reaches a customer. You remain responsible for the Airtable, Slack, and Linear credentials you connect to it.</p>
  </div>
</footer>

<script>
const io = new IntersectionObserver(entries => {
  entries.forEach(e => e.target.classList.toggle('in', e.isIntersecting));
}, { threshold: 0.15, rootMargin: '0px 0px -8% 0px' });

document.querySelectorAll('.reveal-group').forEach(g => {
  [...g.children].forEach((el, i) => {
    el.classList.add('reveal');
    el.style.setProperty('--d', (i % 4) * 70 + 'ms');
  });
});
document.querySelectorAll('.reveal').forEach(el => io.observe(el));
</script>

</body>'''

content = content.replace("</body>", sections)
with open(path, "w") as f:
    f.write(content)
print("inserted all remaining sections into web/index.html")
PYEOF
