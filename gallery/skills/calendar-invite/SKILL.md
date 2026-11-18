---
name: calendar-invite
description: Use when the person wants something added to their calendar from text, an email, a ticket or an itinerary, as an .ics file that opens in any calendar app.
---

# Calendar invite

Python's `icalendar` library is already on your computer. Don't install anything. If a calendar app is connected (Google Calendar, Outlook), offer to add the events there directly instead.

1. Pull out each event: title, date, start and end time, time zone, place, and useful notes (booking codes, gate, address, link).
2. Confirm anything unclear before making the file: a missing time zone, an end time, a date written like 03/04.
3. Write one .ics with every event:

```python
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from icalendar import Calendar, Event, Alarm
import uuid

cal = Calendar()
cal.add("prodid", "-//Casama//EN")
cal.add("version", "2.0")
ev = Event()
ev.add("uid", f"{uuid.uuid4()}@casama.ai")
ev.add("summary", "Flight PR 102 to Tokyo")
ev.add("dtstart", datetime(2026, 12, 3, 9, 40, tzinfo=ZoneInfo("Asia/Manila")))
ev.add("dtend", datetime(2026, 12, 3, 14, 55, tzinfo=ZoneInfo("Asia/Tokyo")))
ev.add("location", "NAIA Terminal 1")
ev.add("description", "Booking ABC123")
alarm = Alarm()
alarm.add("action", "DISPLAY")
alarm.add("trigger", timedelta(hours=-3))
ev.add_component(alarm)
cal.add_component(ev)
open("trip.ics", "wb").write(cal.to_ical())
```

4. Use real time zones (a flight starts and ends in different ones). All-day things use a `date`, not a `datetime`.
5. Hand back the file with a short list of what's in it, and say it opens in Apple Calendar, Google Calendar and Outlook.
