# solshare

Tools for fetching and interacting with your solar and electricity demand data from the [Allume Energy SolCentre](https://solcentre.allumeenergy.com) portal.

## Structure

```
solshare/
├── cli/            # Command-line tool
│   └── solshare.py
├── alexa-skill/    # Alexa voice skill
│   ├── lambda/
│   └── skill-package/
└── API.md          # Allume Energy API reference
```

## CLI

Displays an hourly table of your energy demand vs solar consumption for any time window, with a bar chart showing solar coverage per hour.

```
┌─────────────────────┬────────┬────────┬────────┬──────────────────────────┐
│ Time (AEDT)         │ Demand │  Solar │   Grid │ Solar coverage           │
├─────────────────────┼────────┼────────┼────────┼──────────────────────────┤
│ Thu 26 Feb 07:00    │  0.16  │  0.06  │  0.10  │ █░░░░░░░░░░░░░░░░░░░  38% │
│ Thu 26 Feb 08:00    │  0.13  │  0.00  │  0.13  │ ░░░░░░░░░░░░░░░░░░░░   0% │
│ Thu 26 Feb 11:00    │  1.52  │  1.52  │  0.00  │ ████████████████░░░░ 100% │
│ Thu 26 Feb 19:00    │  1.94  │  0.14  │  1.80  │ █░░░░░░░░░░░░░░░░░░░   7% │
│           ...       │        │        │        │                          │
├─────────────────────┼────────┼────────┼────────┼──────────────────────────┤
│ TOTAL               │ 14.48  │  3.27  │ 11.21  │ Overall solar:  23%    │
└─────────────────────┴────────┴────────┴────────┴──────────────────────────┘
```

All values are in **kWh**. Times are displayed in the **local system timezone**.

### Requirements

Python 3.6+, no third-party libraries required.

### Setup

**1. Clone the repo**

```bash
git clone https://github.com/jquirke/solshare.git
cd solshare
```

**2. Save your credentials**

```bash
python3 cli/solshare.py --email your@email.com --password yourpassword --save
```

This writes `~/.solshare` (mode 600):

```ini
[credentials]
email = your@email.com
password = yourpassword
```

### Usage

```bash
# Last 24 hours (default)
python3 cli/solshare.py

# A specific day
python3 cli/solshare.py --from 2026-02-25

# A date range
python3 cli/solshare.py --from 2026-02-20 --to 2026-02-26
```

| Argument | Description |
|---|---|
| `--from YYYY-MM-DD` | Start date in local time (default: 24 hours ago) |
| `--to YYYY-MM-DD` | End date in local time, inclusive (default: same as `--from`) |
| `--email` | Email address (overrides `~/.solshare`) |
| `--password` | Password (overrides `~/.solshare`) |
| `--save` | Save `--email` and `--password` to `~/.solshare` |

---

## Alexa Skill

Voice skill for Echo devices. Invocation name: **"my solar"**

**Example commands:**
- "Alexa, ask my solar how much solar I'm getting"
- "Alexa, ask my solar if there's surplus solar"
- "Alexa, ask my solar how my solar did today"

The skill is not published to the Alexa skill store. Each user must deploy their own private instance. See below for setup instructions.

### Alexa Skill Setup

**Prerequisites:**
- An [AWS account](https://aws.amazon.com)
- An [Amazon Developer account](https://developer.amazon.com) (same login as your Echo)
- Node.js installed (for the ASK CLI)

**1. Install tools**

```bash
brew install awscli
npm install -g ask-cli
```

**2. Configure AWS and ASK CLI**

```bash
aws configure          # enter your AWS access key and secret
ask configure          # logs in to your Amazon developer account via browser
```

**3. Create a Lambda execution role**

```bash
aws iam create-role \
  --role-name solshare-alexa-lambda-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]
  }'

aws iam attach-role-policy \
  --role-name solshare-alexa-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

**4. Deploy the skill**

```bash
cd alexa-skill
ask deploy
```

This creates the Alexa skill in your developer account and builds the Lambda zip.

**5. Create the Lambda function**

Replace `<YOUR_AWS_ACCOUNT_ID>` and `<YOUR_SKILL_ID>` (from the `ask deploy` output) below:

```bash
aws lambda create-function \
  --function-name solshare-alexa \
  --runtime python3.12 \
  --role arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/solshare-alexa-lambda-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://alexa-skill/.ask/lambda/build.zip \
  --timeout 10 \
  --region ap-southeast-2 \
  --environment "Variables={SOLSHARE_EMAIL=your@email.com,SOLSHARE_PASSWORD=yourpassword}"

aws lambda add-permission \
  --function-name solshare-alexa \
  --statement-id alexa-invoke \
  --action lambda:InvokeFunction \
  --principal alexa-appkit.amazon.com \
  --event-source-token <YOUR_SKILL_ID> \
  --region ap-southeast-2
```

**6. Link Lambda to the skill**

Update `alexa-skill/skill-package/skill.json` — replace the `endpoint.uri` with your Lambda ARN:

```json
"endpoint": {
  "uri": "arn:aws:lambda:ap-southeast-2:<YOUR_AWS_ACCOUNT_ID>:function:solshare-alexa"
}
```

Then redeploy:

```bash
cd alexa-skill && ask deploy
```

Your skill will be available on any Echo registered to your Amazon developer account.

---

## Background

A project to maximise rooftop PV energy received via [Allume Energy's SolShare](https://allumeenergy.com.au) system, which distributes solar energy across apartments in a strata building.

See [API.md](API.md) for full documentation of the underlying Allume Energy API.

---

## Disclaimer

This is an independent, personal project and is not affiliated with, endorsed by, or supported by [Allume Energy](https://allumeenergy.com.au) or SolShare. All trademarks belong to their respective owners.
