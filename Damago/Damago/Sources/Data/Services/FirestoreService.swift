import Combine
import FirebaseFirestore

protocol FirestoreService {
    func observe<T: Decodable>(
        collection: String,
        document: String
    ) -> AnyPublisher<Result<T, Error>, Never>
    func observeQuery<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> AnyPublisher<Result<[T], Error>, Never>
}

final class FirestoreServiceImpl: FirestoreService {
    private var observers: [String: Any] = [:]
    private let lock = NSRecursiveLock()

    func observe<T: Decodable>(
        collection: String,
        document: String
    ) -> AnyPublisher<Result<T, Error>, Never> {
        let path = "\(collection)/\(document)"
        
        return createPublisher(path: path) { completion in
            Firestore.firestore()
                .collection(collection)
                .document(document)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists else { return }

                    do {
                        let decodedData = try snapshot.data(as: T.self)
                        completion(.success(decodedData))
                    } catch {
                        completion(.failure(error))
                    }
                }
        }
    }

    func observeQuery<T: Decodable>(
        collection: String,
        field: String,
        value: Any
    ) -> AnyPublisher<Result<[T], Error>, Never> {
        let path = "\(collection)/where/\(field)==\(value)"

        return createPublisher(path: path) { completion in
            Firestore.firestore()
                .collection(collection)
                .whereField(field, isEqualTo: value)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    do {
                        let decodedData = try snapshot.documents.compactMap { try $0.data(as: T.self) }
                        completion(.success(decodedData))
                    } catch {
                        completion(.failure(error))
                    }
                }
        }
    }

    // MARK: - Private Methods
    
    private func createPublisher<T>(
        path: String,
        listenerProvider: @escaping (@escaping (Result<T, Error>) -> Void) -> ListenerRegistration
    ) -> AnyPublisher<Result<T, Error>, Never> {
        lock.lock()
        defer { lock.unlock() }

        if let existingPublisher = observers[path] as? AnyPublisher<Result<T, Error>, Never> {
            return existingPublisher
        }
        
        let subject = PassthroughSubject<Result<T, Error>?, Never>()
        
        let listener = listenerProvider { result in
            subject.send(result)
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

    private func removeObserver(path: String, listener: ListenerRegistration) {
        lock.lock()
        defer { lock.unlock() }

        listener.remove()
        observers.removeValue(forKey: path)
    }
}
