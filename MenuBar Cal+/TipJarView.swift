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

    func loadProducts(force: Bool = false) async {
        print("TipJarViewModel.loadProducts() called")

        // ať nevoláme StoreKit zbytečně víckrát
        if !force {
            guard products.isEmpty else {
                print("Skipping loadProducts: products already loaded (\(products.count))")
                return
            }
        } else {
            products = []
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
            errorMessage = "support_error_load"
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
            errorMessage = "support_error_purchase"
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(
                domain: "StoreKit",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("support_error_verify", comment: "")]
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

            Text("support_title")
                .font(.title2.bold())

            Text("support_subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("support_loading")
                        .font(.subheadline)
                }
                .padding(.top, 8)

            } else if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(error))
                        .font(.subheadline)

                    Button("support_retry") {
                        Task { await viewModel.loadProducts(force: true) }
                    }
                }
                .padding(.top, 8)

            } else if viewModel.products.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("support_unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("support_retry") {
                        Task { await viewModel.loadProducts(force: true) }
                    }
                }
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
