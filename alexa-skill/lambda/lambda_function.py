"""
Sol Share Alexa Skill - Lambda handler
Fetches energy data from the Allume Energy API and responds to voice queries.

Environment variables (set in Lambda console):
    SOLSHARE_EMAIL    - Allume Energy account email
    SOLSHARE_PASSWORD - Allume Energy account password
"""

import json
import logging
import os
import urllib.request
import urllib.error
from datetime import datetime, timezone, timedelta

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

API_BASE = "https://api.allumeenergy.com.au/v2"
AEDT     = timezone(timedelta(hours=11))


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def api_post(path, payload):
    url  = API_BASE + path
    data = json.dumps(payload).encode()
    req  = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.load(resp)


def api_get(path, token):
    url = API_BASE + path
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.load(resp)


def login():
    email    = os.environ["SOLSHARE_EMAIL"]
    password = os.environ["SOLSHARE_PASSWORD"]
    resp = api_post("/auth/customer-login", {"email": email, "password": password})
    return resp["accessToken"]


def get_property_id(token):
    resp = api_get("/consumers/me/properties", token)
    return resp["properties"][0]["id"]


def get_snapshots(token, property_id, from_ts, to_ts):
    path = f"/properties/{property_id}/snapshots?type=hourly&from={from_ts}&to={to_ts}"
    return api_get(path, token)


# ---------------------------------------------------------------------------
# Data queries
# ---------------------------------------------------------------------------

def current_solar():
    """Fetch the last 30 minutes of data as a live reading."""
    now  = datetime.now(timezone.utc)
    from_ts = int((now - timedelta(minutes=30)).timestamp())
    to_ts   = int(now.timestamp())

    token       = login()
    property_id = get_property_id(token)
    data        = get_snapshots(token, property_id, from_ts, to_ts)

    if not data:
        return None
    return data[-1]


def today_snapshots():
    """Fetch hourly data for today in AEDT (midnight to now)."""
    now      = datetime.now(AEDT)
    midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
    from_ts  = int(midnight.timestamp())
    to_ts    = int(now.timestamp())

    token       = login()
    property_id = get_property_id(token)
    return get_snapshots(token, property_id, from_ts, to_ts)


# ---------------------------------------------------------------------------
# Speech helpers
# ---------------------------------------------------------------------------

def kwh(val):
    """Format kWh value for natural speech."""
    if val < 0.1:
        return f"{val * 1000:.0f} watt hours"
    return f"{val:.2f} kilowatt hours"


def pct(solar, demand):
    if demand <= 0:
        return 0
    return solar / demand * 100


# ---------------------------------------------------------------------------
# Intent handlers
# ---------------------------------------------------------------------------

def handle_current_solar():
    try:
        r = current_solar()
    except Exception as e:
        logger.error("current_solar error: %s", e)
        return speak("Sorry, I couldn't reach your solar data right now. Please try again.")

    if not r:
        return speak("No recent data is available.")

    demand    = r["energyDemand"]
    solar     = max(r["solarConsumed"], 0)
    delivered = max(r["solarDelivered"], 0)
    p         = pct(solar, demand)

    if delivered == 0:
        text = "There is no solar generation at the moment."
    elif p >= 99:
        surplus = round(delivered - solar, 2)
        if surplus > 0:
            text = (f"Solar is covering all of your current demand of {kwh(demand)}, "
                    f"with {kwh(surplus)} surplus being exported to the grid.")
        else:
            text = f"Solar is covering all of your current demand of {kwh(demand)}."
    else:
        text = (f"You are currently using {kwh(solar)} of solar out of {kwh(delivered)} delivered, "
                f"meeting {p:.0f} percent of your demand of {kwh(demand)}.")

    return speak(text)


def handle_surplus():
    try:
        r = current_solar()
    except Exception as e:
        logger.error("surplus error: %s", e)
        return speak("Sorry, I couldn't reach your solar data right now. Please try again.")

    if not r:
        return speak("No recent data is available.")

    demand   = r["energyDemand"]
    solar    = max(r["solarConsumed"], 0)
    exported = max(r["solarExported"], 0)
    delivered = max(r["solarDelivered"], 0)

    if delivered == 0:
        return speak("There is no solar generation at the moment, so no surplus.")

    if exported > 0:
        text = (f"Yes, there is surplus solar. {kwh(exported)} is being exported to the grid. "
                f"Solar is covering all of your current demand of {kwh(demand)}.")
    elif solar >= demand:
        text = "Solar is just meeting your demand with no surplus to export."
    else:
        shortfall = demand - solar
        text = (f"No surplus right now. Solar is meeting {pct(solar, demand):.0f} percent of "
                f"your demand. You are still drawing {kwh(shortfall)} from the grid.")

    return speak(text)


def handle_today_summary():
    try:
        data = today_snapshots()
    except Exception as e:
        logger.error("today_summary error: %s", e)
        return speak("Sorry, I couldn't reach your solar data right now. Please try again.")

    if not data:
        return speak("No data is available for today yet.")

    total_demand    = sum(r["energyDemand"] for r in data)
    total_solar     = sum(max(r["solarConsumed"], 0) for r in data)
    total_delivered = sum(max(r["solarDelivered"], 0) for r in data)
    total_exported  = round(total_delivered - total_solar, 2)
    total_grid      = max(total_demand - total_solar, 0)
    p               = pct(total_solar, total_demand)

    if total_demand == 0:
        return speak("No energy data recorded today yet.")

    text = (f"Today so far, solar has met {p:.0f} percent of your demand. "
            f"You've used {kwh(total_solar)} of solar out of {kwh(total_delivered)} delivered, "
            f"with {kwh(total_exported)} exported to the grid, "
            f"and {kwh(total_grid)} drawn from the grid.")

    return speak(text)


def handle_launch():
    text = ("Welcome to Sol Share. You can ask me how much solar you're getting, "
            "whether there's surplus solar, or how your solar did today.")
    return speak(text, end_session=False)


def handle_help():
    text = ("You can say: how much solar am I getting, is there surplus solar, "
            "or how did my solar do today.")
    return speak(text, end_session=False)


# ---------------------------------------------------------------------------
# Response builder
# ---------------------------------------------------------------------------

def speak(text, end_session=True):
    return {
        "version": "1.0",
        "response": {
            "outputSpeech": {
                "type": "PlainText",
                "text": text
            },
            "shouldEndSession": end_session
        }
    }


# ---------------------------------------------------------------------------
# Main handler
# ---------------------------------------------------------------------------

def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))

    request_type = event["request"]["type"]

    if request_type == "LaunchRequest":
        return handle_launch()

    if request_type == "SessionEndedRequest":
        return {"version": "1.0", "response": {}}

    if request_type == "IntentRequest":
        intent = event["request"]["intent"]["name"]

        if intent == "CurrentSolarIntent":
            return handle_current_solar()
        if intent == "SurplusIntent":
            return handle_surplus()
        if intent == "TodaySummaryIntent":
            return handle_today_summary()
        if intent in ("AMAZON.HelpIntent",):
            return handle_help()
        if intent in ("AMAZON.CancelIntent", "AMAZON.StopIntent", "AMAZON.NavigateHomeIntent"):
            return speak("Goodbye.")

    return speak("Sorry, I didn't understand that.")
