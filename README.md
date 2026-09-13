# Verity

**Live demo:** [DEMO_VIDEO_URL_HERE]
**Landing page:** [LANDING_PAGE_URL_HERE]

**Want to verify the reliability claims yourself, with zero setup?** No API keys needed:
```
git clone https://github.com/Kingnanaweb3/verity
cd verity
pip install anthropic httpx python-dotenv rich groq
python3 -m evals.run_evals
```
10 scenarios, fully mocked, runs in under 6ms. This checks the same retry logic,
idempotency, allow list, and verifier behavior described below, independently
of anything claimed in this document.

Think about a busy manager who has ten people reporting to them. Every Friday, that manager asks each person "did you finish the thing you told me you'd finish?" Most people say yes. The manager believes them. Most of the time that trust is fine. But every so often, someone says yes when the real answer is "mostly, but not quite," and the manager only finds out three weeks later when a customer complains.

Verity is built for the version of this problem that happens with AI agents instead of people. An AI agent can say "I posted the message" and "I updated the ticket" with total confidence, and that confidence can be wrong. Not because the agent is lying on purpose. It just does not always check its own work.

So Verity checks it for you.

## What it actually does

Picture a small business with forty customer accounts sitting in a spreadsheet. Some of those accounts are quiet in a normal way, like a customer who only checks in once a season. Some are quiet in a worrying way, like a customer who usually talks to you every week and has gone silent for a month.

Verity reads that spreadsheet (an Airtable base, in this build) and asks one simple question about every account: is this account quieter than its own normal pattern, not quieter than some made up number that applies to everyone. A customer who checks in every thirty days is not "stalled" just because thirty days passed. A customer who checks in every seven days and has been gone for three weeks is a different story.

When Verity finds an account like that, it writes a short draft message explaining why the account was flagged, and posts that draft to a Slack channel for a human to look at. It does not send anything to the actual customer. A person has to approve it first. Verity also creates or updates a ticket in Linear so the follow up does not get lost.

That much, on its own, is a normal automation. Plenty of tools do this. Here is the part that is not normal.

## The part that makes this different

After Verity finishes a run, it does something most agents never bother to do. It goes back and checks its own work, the way you might reread an email after you hit send, except Verity does it by actually opening Slack again and actually opening Linear again, and looking with fresh eyes at what is really there.

If Verity says "I posted a message to Slack," a separate piece of code reopens that Slack channel and looks for the message. If it is really there, that gets marked confirmed. If it is not there for any reason, that gets marked as a mismatch, out loud, in the report. Same idea for Linear. The agent's own claim and the actual state of the world are never allowed to be the same thing by assumption. They have to agree by evidence.

This matters because of something that keeps showing up in research on AI agents right now. Agents are good at doing work. They are less reliable at knowing when they only did half the work, or at admitting when a step silently failed. A recent benchmark on multi app agents found that the single biggest failure pattern was not agents doing the wrong thing. It was agents doing most of the right thing, then reporting success anyway while skipping the one step that actually mattered, like the message a human was supposed to approve.

Verity's answer to that is simple. Do not just trust the agent's report card. Go check the actual test.

## How a run actually goes, step by step

1. Verity reads every account from Airtable.
2. It compares each account's quiet time against that account's own normal rhythm, not a generic number.
3. For every account that looks genuinely stalled, it writes a short, specific reason (not a vague one) and drafts an outreach message.
4. That draft goes to Slack, waiting for a human to approve it. Nothing reaches a real customer without that approval.
5. A ticket goes into Linear so the account does not get forgotten.
6. Once the run is done, a separate verification step reopens Slack and Linear and checks, independently, whether those two things actually happened.
7. A report prints showing what was claimed, and what was actually confirmed. Anything that does not match gets flagged, not hidden.

If you run Verity twice on the same account without anything changing, it recognizes that already happened and does not send a second message or make a second ticket. That check happens before anything gets written, using a small local ledger that remembers what was already done.

## Running it yourself

You will need four things in a `.env` file, copied from `.env.example`:

- An Airtable API key and base ID, with a table called Accounts (or set the table name/ID directly)
- A Slack bot token, with the bot invited into whatever channel you want drafts posted to
- A Linear API key and your team ID
- A Groq API key, since the actual thinking part of the agent runs on Groq

Then, from the project folder:

```
pip install anthropic httpx python-dotenv rich groq
python3 -m agent.main --dry-run
```

Dry run mode reads everything and tells you what it would do, without touching Slack or Linear at all. That is the safe way to first see it work. When you are ready for it to actually post and actually create tickets:

```
python3 -m agent.main --apply
```

You can also break things on purpose, on demand, to see how Verity handles it:

```
python3 -m agent.main --apply --fault slack:500
python3 -m agent.main --apply --fault linear:429
```

The first one pretends Slack is down. The second pretends Linear is rate limiting you. Verity is built to notice both and keep going sensibly instead of falling over.

## Checking the reliability claims without touching real accounts

There is a second way to test Verity that does not need any real credentials at all. Ten specific situations, from a clean happy path all the way to "the agent lied about finishing," are recreated using fake responses instead of real ones, so they run in milliseconds and give the same result every time.

```
python3 -m evals.run_evals
```

Full detail on what each of those ten situations is testing, and why, lives in RELIABILITY.md.

## What is under the hood

Everything Verity does lives in a small set of files, each with one job:

- `agent/infra/http.py` is the only place any network request happens. Every retry, every simulated fault, every log entry, funnels through here.
- `agent/infra/ledger.py` remembers what has already been done, so nothing gets repeated by accident.
- `agent/infra/trace.py` writes a plain, readable log of every step Verity took during a run.
- `agent/tools/` holds the actual connections to Airtable, Slack, and Linear.
- `agent/tools/registry.py` is the short list of things Verity is allowed to do. Nothing outside that list can run, no matter what the model decides, and no matter what a stray instruction hidden inside customer data might try to suggest.
- `agent/loop.py` is where the model actually thinks, one step at a time, with a hard limit on how many steps it can take before it has to stop and report.
- `agent/verifier.py` is the part described above. It never trusts the agent's own word.

## Known gaps, honestly

Verity is a one day build, not a finished product, and it is worth saying plainly where the edges are.

The eval suite runs against realistic fake responses, not live third party services, because a rate limit or an authentication failure is not something you can reliably trigger on a real account on command. What is not faked is the actual decision making code. Every scenario runs the real retry logic, the real ledger, the real allow list, and the real verifier, just against a stand in response instead of a live one.

During the real, live build, a genuine bug did show up. Verity claimed a Slack message had posted, and the verifier correctly caught that it could not confirm it, because the Slack app's permission scopes were missing one needed to read channel history back. That is not a hypothetical example written for this document. It happened, it got diagnosed from the verifier's own honest report, and it got fixed, and then confirmed fixed the same way, by checking again rather than assuming.

If anything, that is the best proof this idea works. The system caught its own real mistake, not a scripted one.
