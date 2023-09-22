import AuthenticationClient
import ComposableArchitecture
import LoginCore
import SwiftUI
import TwoFactorCore
import TwoFactorSwiftUI

@WithViewStore(for: Login.self)
public struct LoginView: View {
  @State var store: StoreOf<Login>

  public init(store: StoreOf<Login>) {
    self.store = store
  }

  public var body: some View {
    Form {
      Text(
        """
        To login use any email and "password" for the password. If your email contains the \
        characters "2fa" you will be taken to a two-factor flow, and on that screen you can \
        use "1234" for the code.
        """
      )

      Section {
        TextField("blob@pointfree.co", text: self.$store.email)
          .autocapitalization(.none)
          .keyboardType(.emailAddress)
          .textContentType(.emailAddress)
        SecureField("••••••••", text: self.$store.password)
      }

      Button {
        // NB: SwiftUI will print errors to the console about "AttributeGraph: cycle detected" if
        //     you disable a text field while it is focused. This hack will force all fields to
        //     unfocus before we send the action to the view store.
        // CF: https://stackoverflow.com/a/69653555
        _ = UIApplication.shared.sendAction(
          #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
        self.send(.loginButtonTapped)
      } label: {
        HStack {
          Text("Log in")
          if self.store.isLoginRequestInFlight {
            Spacer()
            ProgressView()
          }
        }
      }
      .disabled(!self.store.isFormValid)
    }
    .disabled(self.store.isLoginRequestInFlight)
    .alert(store: self.store.scope(#feature(\.$alert)))
    .navigationDestination(item: self.$store.scope(#feature(\.twoFactor))) { store in
      TwoFactorView(store: store)
    }
    .navigationTitle("Login")
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      LoginView(
        store: Store(initialState: Login.State()) {
          Login()
        } withDependencies: {
          $0.authenticationClient.login = { _ in
            AuthenticationResponse(token: "deadbeef", twoFactorRequired: false)
          }
          $0.authenticationClient.twoFactor = { _ in
            AuthenticationResponse(token: "deadbeef", twoFactorRequired: false)
          }
        }
      )
    }
  }
}
