import StoreKit

@MainActor
final class StoreKitTransactionListener {
    static let shared = StoreKitTransactionListener()
    private var task: Task<Void, Never>?

    func start() {
        guard task == nil else { return }

        task = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                } catch {
                    // klidně jen ignoruj / případně logni
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: 0)
        case .verified(let safe):
            return safe
        }
    }
}
