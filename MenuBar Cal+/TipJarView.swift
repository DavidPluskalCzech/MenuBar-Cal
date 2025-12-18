import SwiftUI
import StoreKit
import Combine

// MARK: - ViewModel pro Tip Jar (StoreKit 2)

@MainActor
final class TipJarViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIDs = [
        "com.davethepcguy.calendarbar.tip.small",
        "com.davethepcguy.calendarbar.tip.medium",
        "com.davethepcguy.calendarbar.tip.large"
    ]

    func loadProducts() async {
        print("TipJarViewModel.loadProducts() called")

        // ať nevoláme StoreKit zbytečně víckrát
        guard products.isEmpty else {
            print("Skipping loadProducts: products already loaded (\(products.count))")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            print("Fetching products for IDs: \(productIDs)")
            var fetched = try await Product.products(for: productIDs)
            print("Fetched products count: \(fetched.count)")

            fetched.sort { $0.price < $1.price }
            products = fetched

        } catch {
            print("ERROR fetching products: \(error.localizedDescription)")
            errorMessage = "Nepodařilo se načíst možnosti podpory. Zkuste to prosím později."
        }

        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return true

            case .userCancelled, .pending:
                return false

            default:
                return false
            }
        } catch {
            errorMessage = "Platbu se nepodařilo dokončit. Zkuste to prosím znovu."
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(
                domain: "StoreKit",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Nelze ověřit nákup."]
            )
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - TipJarView – UI

struct TipJarView: View {
    @Binding var showThanksAlert: Bool
    @StateObject private var viewModel = TipJarViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Podpora vývoje")
                .font(.title2.bold())

            Text("Pokud ti CalendarBar dělá radost, můžeš dobrovolně podpořit vývoj. Nákupy jsou jednorázové, bez předplatného.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Načítám možnosti podpory…")
                        .font(.subheadline)
                }
                .padding(.top, 8)

            } else if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(.subheadline)

                    Button("Zkusit znovu") {
                        Task { await viewModel.loadProducts() }
                    }
                }
                .padding(.top, 8)

            } else if viewModel.products.isEmpty {
                Text("Možnosti podpory zatím nejsou dostupné. Zkontroluj připojení k internetu nebo že aplikace běží z App Store / s testovací StoreKit konfigurací.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

            } else {
                ForEach(viewModel.products, id: \.id) { product in
                    Button {
                        Task {
                            let success = await viewModel.purchase(product)
                            if success { showThanksAlert = true }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.displayName)
                                    .font(.headline)

                                if !product.description.isEmpty {
                                    Text(product.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(product.displayPrice)
                                .font(.headline)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        
        .task {
            await viewModel.loadProducts()
        }
        
    }
}
