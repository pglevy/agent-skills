# Meeting Room Booking Flow - OUTLINE

## Flow Goal
Enable users to find, select, and book meeting rooms with time conflict awareness and calendar integration

## Screen 1: Find Room
- input: □ Date picker
- input: □ Time range
- input: □ Capacity filter
- display: Conference A (6 people • Projector)
- display: Conference B (12 people • TV)
- display: Huddle Room (4 people • Phone)
- button: Select Room
- note: Filter by equipment?

## Screen 2: Conference A
- display: Thursday, Dec 15
- display: Room details and capacity
- input: □ 9:00-10:00 AM
- input: □ 10:30-11:30 AM
- display: 2:00-3:00 PM (Booked) [unavailable]
- input: □ 3:30-4:30 PM
- button: Continue

## Screen 3: Meeting Details
- input: □ Meeting Title [text field]
- input: □ Add Attendees [email inputs]
- input: □ Send calendar invite
- display: Conf A • 10:30-11:30 AM
- button: Book Room [primary]
- note: Setup time needed? [right]

## Screen 4: Room Booked [email-screen]
- confirm: ✓ Conference A reserved
- display: Thu, Dec 15 (10:30-11:30 AM)
- display: Calendar invite sent to 4 people
- button: View Booking [secondary]
- button: Done [primary]