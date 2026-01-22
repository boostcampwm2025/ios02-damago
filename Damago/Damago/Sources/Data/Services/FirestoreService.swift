import Combine
import FirebaseFirestore

protocol FirestoreService {
    func observe<T: Decodable>(collection: String, document: String) -> AnyPublisher<Result<T, Error>, Never>
}

final class FirestoreServiceImpl: FirestoreService {
    private var observers: [String: Any] = [:]
    private let lock = NSRecursiveLock()

    // swiftlint:disable trailing_closure
    func observe<T: Decodable>(collection: String, document: String) -> AnyPublisher<Result<T, Error>, Never> {
        lock.lock()
        defer { lock.unlock() }

        let path = "\(collection)/\(document)"

        if let existingObserver = observers[path] as? AnyPublisher<Result<T, Error>, Never> {
            return existingObserver
        }

        let subject = PassthroughSubject<Result<T, Error>?, Never>()

        let listener = Firestore.firestore()
            .collection(collection)
            .document(document)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(.failure(error))
                    return
                }

                guard let snapshot = snapshot, snapshot.exists else { return }

                do {
                    let decodedData = try snapshot.data(as: T.self)
                    subject.send(.success(decodedData))
                } catch {
                    subject.send(.failure(error))
                }
            }

        let publisher = subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.removeObserver(path: path, listener: listener)
            })
            .multicast { CurrentValueSubject<Result<T, Error>?, Never>(nil) }
            .autoconnect()
            .compactMap { $0 }
            .eraseToAnyPublisher()

        observers[path] = publisher
        return publisher
    }
    // swiftlint:enable trailing_closure

    private func removeObserver(path: String, listener: ListenerRegistration) {
        lock.lock()
        defer { lock.unlock() }

        listener.remove()
        observers.removeValue(forKey: path)
    }
}
