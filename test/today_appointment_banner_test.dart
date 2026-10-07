import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/my_appointments_model.dart';
import 'package:hemlukart_app/widgets/today_appointment_banner_card.dart';

void main() {
  group('TodayAppointmentBannerCard Tests', () {
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayStr =
        '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${nowIst.day.toString().padLeft(2, '0')}';
    final yesterdayStr =
        '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${(nowIst.day - 1).toString().padLeft(2, '0')}';
    final tomorrowStr =
        '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${(nowIst.day + 1).toString().padLeft(2, '0')}';

    UserAppointmentItem createApt({
      required String id,
      required String date,
      required String time,
      required String status,
      String patientName = 'Ramesh Kumar',
      String doctorName = 'Dr. Sharma',
    }) {
      return UserAppointmentItem(
        id: id,
        appointmentDate: date,
        appointmentTime: time,
        durationMinutes: 30,
        consultationType: 'video',
        status: status,
        paymentStatus: 'paid',
        consultationFee: '500',
        patientName: patientName,
        doctorName: doctorName,
      );
    }

    test('isToday returns true for today in IST and false for other dates', () {
      expect(TodayAppointmentBannerCard.isToday(todayStr), isTrue);
      expect(TodayAppointmentBannerCard.isToday(yesterdayStr), isFalse);
      expect(TodayAppointmentBannerCard.isToday(tomorrowStr), isFalse);
      expect(TodayAppointmentBannerCard.isToday(null), isFalse);
      expect(TodayAppointmentBannerCard.isToday(''), isFalse);
    });

    test('Returns null if appointment list is empty', () {
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment([]);
      expect(res, isNull);
    });

    test('Returns null if appointment is for yesterday or tomorrow', () {
      final apts = [
        createApt(id: '1', date: yesterdayStr, time: '10:00 AM', status: 'confirmed'),
        createApt(id: '2', date: tomorrowStr, time: '11:00 AM', status: 'confirmed'),
      ];
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment(apts);
      expect(res, isNull);
    });

    test('Excludes completed and cancelled appointments', () {
      final apts = [
        createApt(id: '1', date: todayStr, time: '10:00 AM', status: 'completed'),
        createApt(id: '2', date: todayStr, time: '11:00 AM', status: 'cancelled'),
      ];
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment(apts);
      expect(res, isNull);
    });

    test('Shows active today appointment and picks exactly one', () {
      final apts = [
        createApt(id: '1', date: todayStr, time: '10:00 AM', status: 'confirmed'),
        createApt(id: '2', date: todayStr, time: '02:00 PM', status: 'confirmed'),
      ];
      // Run with morning current time (09:00 AM = 540 min)
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment(
        apts,
        customCurrentMinutes: 540,
      );
      expect(res, isNotNull);
      expect(res!.id, '1');
      expect(res.appointmentTime, '10:00 AM');
    });

    test('When first appointment is completed, the NEXT scheduled today appointment is displayed', () {
      // Apt 1 is completed, Apt 2 is scheduled
      final apts = [
        createApt(id: '1', date: todayStr, time: '10:00 AM', status: 'completed'),
        createApt(id: '2', date: todayStr, time: '02:00 PM', status: 'confirmed'),
      ];
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment(
        apts,
        customCurrentMinutes: 540,
      );
      expect(res, isNotNull);
      expect(res!.id, '2');
      expect(res.appointmentTime, '02:00 PM');
    });

    test('Prioritizes in-progress appointment over scheduled appointments', () {
      final apts = [
        createApt(id: '1', date: todayStr, time: '10:00 AM', status: 'confirmed'),
        createApt(id: '2', date: todayStr, time: '11:00 AM', status: 'in_progress'),
      ];
      final res = TodayAppointmentBannerCard.getNextActiveTodayAppointment(
        apts,
        customCurrentMinutes: 540,
      );
      expect(res, isNotNull);
      expect(res!.id, '2');
      expect(res.status, 'in_progress');
    });

    test('Filters out past appointments today once meeting time and duration has expired', () {
      // Apt 1: 10:00 AM - 10:30 AM
      // Apt 2: 02:00 PM - 02:30 PM
      final apts = [
        createApt(id: '1', date: todayStr, time: '10:00 AM', status: 'confirmed'),
        createApt(id: '2', date: todayStr, time: '02:00 PM', status: 'confirmed'),
      ];

      // At 10:45 AM (645 min): Apt 1 has passed/expired. Only Apt 2 should show!
      final resAt1045 = TodayAppointmentBannerCard.getNextActiveTodayAppointment(
        apts,
        customCurrentMinutes: 645,
      );
      expect(resAt1045, isNotNull);
      expect(resAt1045!.id, '2');
      expect(resAt1045.appointmentTime, '02:00 PM');

      // At 03:00 PM (900 min): Both appointments have expired. Returns null!
      final resAt1500 = TodayAppointmentBannerCard.getNextActiveTodayAppointment(
        apts,
        customCurrentMinutes: 900,
      );
      expect(resAt1500, isNull);
    });

    test('isExpiredOrPast correctly identifies past, ongoing, and future appointments', () {
      final apt = createApt(id: '20', date: todayStr, time: '10:00 AM', status: 'confirmed');
      // 10:00 AM (600 min) with 30 min duration -> ends at 10:30 AM (630 min)

      // Future: 09:30 AM (570 min) -> NOT past/expired
      expect(TodayAppointmentBannerCard.isExpiredOrPast(apt, customCurrentMinutes: 570), isFalse);

      // Ongoing: 10:15 AM (615 min) -> NOT past/expired
      expect(TodayAppointmentBannerCard.isExpiredOrPast(apt, customCurrentMinutes: 615), isFalse);

      // Ended: 10:30 AM (630 min) -> expired/ended
      expect(TodayAppointmentBannerCard.isExpiredOrPast(apt, customCurrentMinutes: 630), isTrue);

      // Past: 11:00 AM (660 min) -> expired/ended
      expect(TodayAppointmentBannerCard.isExpiredOrPast(apt, customCurrentMinutes: 660), isTrue);
    });

    test('Video call activates exactly 10 minutes before scheduled meeting time', () {
      final apt = createApt(id: '10', date: todayStr, time: '10:00 AM', status: 'confirmed');
      // 10:00 AM is 600 minutes from midnight. Window starts at 590 minutes (09:50 AM).

      // 15 minutes before (09:45 AM = 585 mins) -> NOT active
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 585), isFalse);

      // 11 minutes before (09:49 AM = 589 mins) -> NOT active
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 589), isFalse);

      // Exactly 10 minutes before (09:50 AM = 590 mins) -> ACTIVE!
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 590), isTrue);

      // 5 minutes before (09:55 AM = 595 mins) -> ACTIVE!
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 595), isTrue);

      // During meeting start (10:05 AM = 605 mins) -> ACTIVE!
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 605), isTrue);

      // After meeting expires (10:35 AM = 635 mins) -> NOT active (expired)
      expect(TodayAppointmentBannerCard.canJoinVideoCall(apt, customCurrentMinutes: 635), isFalse);
    });

    test('Video call cannot be activated if appointment status is pending or unconfirmed', () {
      final pendingApt = createApt(id: '11', date: todayStr, time: '10:00 AM', status: 'pending');

      // Even within 10 minutes or past time, pending appointment cannot join video call
      expect(TodayAppointmentBannerCard.canJoinVideoCall(pendingApt, customCurrentMinutes: 595), isFalse);
      expect(TodayAppointmentBannerCard.canJoinVideoCall(pendingApt, customCurrentMinutes: 605), isFalse);
    });

    test('In-progress video call can always be joined regardless of time', () {
      final inProgressApt = createApt(id: '12', date: todayStr, time: '10:00 AM', status: 'in_progress');
      expect(TodayAppointmentBannerCard.canJoinVideoCall(inProgressApt, customCurrentMinutes: 500), isTrue);
    });

    test('Chat is enabled for confirmed and in-progress appointments, disabled for pending, completed, cancelled, ended', () {
      final confirmedApt = createApt(id: '13', date: todayStr, time: '10:00 AM', status: 'confirmed');
      final inProgressApt = createApt(id: '14', date: todayStr, time: '10:00 AM', status: 'in_progress');
      final pendingApt = createApt(id: '15', date: todayStr, time: '10:00 AM', status: 'pending');
      final completedApt = createApt(id: '16', date: todayStr, time: '10:00 AM', status: 'completed');
      final cancelledApt = createApt(id: '17', date: todayStr, time: '10:00 AM', status: 'cancelled');
      final endedApt = createApt(id: '18', date: todayStr, time: '10:00 AM', status: 'ended');

      expect(TodayAppointmentBannerCard.canChat(confirmedApt), isTrue);
      expect(TodayAppointmentBannerCard.canChat(inProgressApt), isTrue);
      expect(TodayAppointmentBannerCard.canChat(pendingApt), isFalse);
      expect(TodayAppointmentBannerCard.canChat(completedApt), isFalse);
      expect(TodayAppointmentBannerCard.canChat(cancelledApt), isFalse);
      expect(TodayAppointmentBannerCard.canChat(endedApt), isFalse);
    });

    test('getCallEnableTimeString formats time exactly 10 minutes before', () {
      final apt10Am = createApt(id: '18', date: todayStr, time: '10:00 AM', status: 'confirmed');
      final apt2Pm = createApt(id: '19', date: todayStr, time: '02:00 PM', status: 'confirmed');

      expect(TodayAppointmentBannerCard.getCallEnableTimeString(apt10Am), '09:50 AM');
      expect(TodayAppointmentBannerCard.getCallEnableTimeString(apt2Pm), '01:50 PM');
    });
  });
}

