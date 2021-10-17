import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart';

void main() => runApp(GoogleCalendarEvents());

class GoogleCalendarEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Calendar',
      home: CalendarEvents(),
    );
  }
}

class CalendarEvents extends StatefulWidget {
  @override
  CalendarEventsState createState() => CalendarEventsState();
}

class CalendarEventsState extends State<CalendarEvents> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '27836071630-m5ch3l1en2olrstkuc2etlq2fp6k92rh.apps.googleusercontent.com',
    scopes: <String>[
      CalendarApi.calendarScope,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text('Event Calendar'),
      ),
      body: Container(
        child: FutureBuilder(
          future: getGoogleEventsData(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return Container(
                child: Stack(
              children: [
                Container(
                  child: SfCalendar(
                    view: CalendarView.month,
                    initialDisplayDate: DateTime(2020, 7, 15, 9, 0, 0),
                    dataSource: GoogleDataSource(events: snapshot.data),
                    monthViewSettings: MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment),
                  ),
                ),
                snapshot.data != null
                    ? Container()
                    : Center(
                        child: CircularProgressIndicator(),
                      )
              ],
            ));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_googleSignIn.currentUser != null) {
      _googleSignIn.disconnect();
      _googleSignIn.signOut();
    }

    super.dispose();
  }

  Future<List<Event>> getGoogleEventsData() async {
    try {
      final googleUser = await (_googleSignIn.signIn());
      final GoogleAPIClient httpClient =
          GoogleAPIClient(await googleUser!.authHeaders);
      final CalendarApi calendarAPI = CalendarApi(httpClient);
      final Events calEvents = await calendarAPI.events.list(
        "primary",
      );
      final List<Event> appointments = <Event>[];
      if (calEvents != null && calEvents.items != null) {
        for (int i = 0; i < calEvents.items!.length; i++) {
          final Event event = calEvents.items![i];
          if (event.start == null) {
            continue;
          }
          appointments.add(event);
        }
      }
      return appointments;
    } catch (e) {
      print(e.toString());
    }
    return [];
  }
}

class GoogleDataSource extends CalendarDataSource {
  GoogleDataSource({List<Event>? events}) {
    this.appointments = events;
  }

  @override
  DateTime getStartTime(int index) {
    final Event event = appointments![index];
    return event.start!.date ?? event.start!.dateTime!.toLocal();
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].start.date != null;
  }

  @override
  DateTime getEndTime(int index) {
    final Event event = appointments![index];
    return event.endTimeUnspecified != null && event.endTimeUnspecified!
        ? (event.start!.date ?? event.start!.dateTime!.toLocal())
        : (event.end!.date != null
            ? event.end!.date!.add(Duration(days: -1))
            : event.end!.dateTime!.toLocal());
  }

  @override
  String? getLocation(int index) {
    return appointments![index].location;
  }

  @override
  String? getNotes(int index) {
    return appointments![index].description;
  }

  @override
  String getSubject(int index) {
    final Event event = appointments![index];
    return event.summary == null || event.summary!.isEmpty
        ? 'No Title'
        : event.summary!;
  }
}

class GoogleAPIClient extends IOClient {
  Map<String, String>? _headers;

  GoogleAPIClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers!));

  @override
  Future<Response> head(Object url, {Map<String, String>? headers}) =>
      super.head(url as Uri, headers: headers!..addAll(_headers!));
}
