//
//  TodayDiptychViewModel.swift
//  Diptych
//
//  Created by 김민 on 2023/07/19.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

enum TodayDiptychState {
    case incomplete
    case upload
    case complete
}

enum DiptychState {
    case none
    case incomplete
    case todayIncomplete
    case todayfirst
    case todaySecond
    case complete
}

final class TodayDiptychViewModel: ObservableObject {

    // MARK: - Properties

    @Published var question = ""
    @Published var currentUser: DiptychUser?
    @Published var isFirst = true
    @Published var weeklyData = [WeeklyData]()
    @Published var content: Content?
    @Published var todayPhoto: Photo?
    @Published var photoFirstURL = ""
    @Published var photoSecondURL = ""
    @Published var isCompleted = false
    @Published var photoFirstState = TodayDiptychState.incomplete
    @Published var photoSecondState = TodayDiptychState.incomplete
    @Published var diptychNumber = 1
    private let db = Firestore.firestore()

    // MARK: - Network

    func fetchWeeklyCalender() async {
        guard let albumId = currentUser?.coupleAlbumId else { return }

        do {
            let querySnapshot = try await db.collection("photos")
                .whereField("albumId", isEqualTo: albumId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: calculateThisMondayDate()))
                .whereField("date", isLessThan: calculateTodayTimestamp())
                .getDocuments()

            for document in querySnapshot.documents {
                let photo = try document.data(as: Photo.self)
                let isCompleted = photo.isCompleted
                let date = Date(timeIntervalSince1970: TimeInterval(photo.date.seconds))
                guard let day = Calendar.current.dateComponents([.day], from: date).day else { return }

                weeklyData.append(WeeklyData(date: day, diptychState: isCompleted ? DiptychState.complete : DiptychState.incomplete))
            }

            guard let todayPhoto = self.todayPhoto else { return }
            let date = Date(timeIntervalSince1970: TimeInterval(todayPhoto.date.seconds))
            guard let day = Calendar.current.dateComponents([.day], from: date).day else { return }

            if todayPhoto.isCompleted {
                weeklyData.append(WeeklyData(date: day, diptychState: .complete))
            } else if !todayPhoto.photoFirst.isEmpty && todayPhoto.photoSecond.isEmpty {
                weeklyData.append(WeeklyData(date: day, diptychState: .todayfirst))
            } else if todayPhoto.photoFirst.isEmpty && !todayPhoto.photoSecond.isEmpty {
                weeklyData.append(WeeklyData(date: day, diptychState: .todaySecond))
            } else {
                weeklyData.append(WeeklyData(date: day, diptychState: .todayIncomplete))
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func fetchTodayImage() async {
        let (todayDate, _, _) = setTodayCalendar()
        let timestamp = Timestamp(date: todayDate)
        guard let albumId = currentUser?.coupleAlbumId else { return }

        do {
            let querySnapshot = try await db.collection("photos")
                .whereField("albumId", isEqualTo: albumId)
                .whereField("date", isGreaterThanOrEqualTo: timestamp)
                .getDocuments()

            for document in querySnapshot.documents {
                self.todayPhoto = try document.data(as: Photo.self)
            }

            await downloadImage()

            if !photoFirstURL.isEmpty && !photoSecondURL.isEmpty {
                photoFirstState = .complete
                photoSecondState = .complete
            } else if !photoFirstURL.isEmpty || !photoSecondURL.isEmpty {
                photoFirstState = photoFirstURL.isEmpty ? .incomplete : .upload
                photoSecondState = photoSecondURL.isEmpty ? .incomplete : .upload
            } else {
                photoFirstState = .incomplete
                photoSecondState = .incomplete
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func fetchCompleteState() async {
        guard let todayPhoto = todayPhoto else { return }
        isCompleted = todayPhoto.isCompleted
    }

    func downloadImage() async {
        guard let todayPhoto = todayPhoto else { return }
        if todayPhoto.photoFirst != "" {
            photoFirstURL = todayPhoto.photoFirst
        }

        if todayPhoto.photoSecond != "" {
            photoSecondURL = todayPhoto.photoSecond
        }
    }

    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            self.currentUser = try? snapshot.data(as: DiptychUser.self)
        } catch {
            print(error.localizedDescription)
        }
    }

    func setUserCameraLoactionState() async {
        guard let isFirst = currentUser?.isFirst else { return }
        self.isFirst = isFirst
    }

    func fetchContents() async {
        guard let albumId = currentUser?.coupleAlbumId else { return }

        do {
            let daySnapshot = try await db.collection("albums")
                .whereField("id", isEqualTo: albumId)  
                .getDocuments()

            let data = daySnapshot.documents[0].data()
            guard let startDate = data["startDate"] as? Timestamp else { return }

            let dateComponents = Calendar.current.dateComponents([.day], from: startDate.dateValue(), to: Date())
            guard var order = dateComponents.day else { return }

            let contentsCount = try await db.collection("contents").getDocuments().count
            let contentSnapshot = try await db.collection("contents")
                .whereField("order", isEqualTo: order % contentsCount)
                .getDocuments()

            self.content = try contentSnapshot.documents[0].data(as: Content.self)
            guard let question = content?.question else { return }
            self.question = question.replacingOccurrences(of: "\\n", with: "\n")
        } catch {
            print(error.localizedDescription)
        }
    }

    func setTodayPhoto() async {
        let (todayDate, _, _) = setTodayCalendar()
        let timestamp = Timestamp(date: todayDate)
        guard let albumId = currentUser?.coupleAlbumId else { return }

        do {
            let querySnapshot = try await db.collection("photos")
                .whereField("albumId", isEqualTo: albumId)
                .whereField("date", isEqualTo: timestamp)
                .getDocuments()

            if querySnapshot.documents.isEmpty {
                let autoGeneratedId = self.db.collection("photos").document().documentID
                try await db.collection("photos").document(autoGeneratedId).setData(
                    Photo(id: autoGeneratedId,
                          photoFirst: "",
                          photoSecond: "",
                          thumbnail: "",
                          date: timestamp,
                          contentId: "",
                          albumId: albumId,
                          isCompleted: false)
                    .convertToDictionary()
                )
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func setDiptychNumber() async {
        guard let albumId = currentUser?.coupleAlbumId else { return }

        do {
            let querySnapshot = try await db.collection("photos")
                .whereField("albumId", isEqualTo: albumId)
                .whereField("isCompleted", isEqualTo: true)
                .getDocuments()
            
            diptychNumber += querySnapshot.documents.count

            guard let isCompleted = todayPhoto?.isCompleted else { return }
            if isCompleted { diptychNumber -= 1 }

        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - Custom Methods

    func setTodayCalendar() -> (Date, Calendar, Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 00:00:00"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        let todayDateString = formatter.string(from: Date())
        let todayDate = formatter.date(from: todayDateString)!

        let currentWeekday = calendar.component(.weekday, from: todayDate)
        let daysAfterMonday = (currentWeekday + 5) % 7

        return (todayDate, calendar, daysAfterMonday)
    }

    func setTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        let todayDateString = formatter.string(from: Date())

        return todayDateString
    }

    func calculateThisMondayDate() -> Date {
        let (todayDate, calendar, daysAfterMonday) = setTodayCalendar()
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysAfterMonday, to: todayDate) else { return Date() }
        return thisMonday
    }

    func calculateTodayTimestamp() -> Timestamp {
        let (todayDate, _, _) = setTodayCalendar()
        let timestamp = Timestamp(date: todayDate)
        return timestamp
    }

    func setWeeklyDates() -> [Int] {
         let calendar = Calendar.current
         let weekday = calendar.component(.weekday, from: calculateThisMondayDate())
         let daysToAdd = (2...8).map { $0 - weekday }
         let weeklyDates = daysToAdd.map { calendar.date(byAdding: .day,
                                                         value: $0,
                                                         to: calculateThisMondayDate())! }
                                     .map { calendar.component(.day, from: $0) }
         return weeklyDates
     }
}
