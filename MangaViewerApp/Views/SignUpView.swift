import SwiftUI
import PhotosUI
import FirebaseAuth

struct SignUpView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var nickname = ""
    @State private var profileImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Créer un compte")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 30)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = uiImage
                            }
                        }
                    }

                    Group {
                        TextField("Prénom", text: $firstName)
                        TextField("Nom", text: $lastName)
                        TextField("Pseudo", text: $nickname)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        SecureField("Mot de passe", text: $password)
                        SecureField("Confirmer le mot de passe", text: $confirmPassword)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Les mots de passe ne correspondent pas")
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: {
                        if fieldsAreValid() {
                            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                                if let error = error {
                                    print("Erreur création compte : \(error.localizedDescription)")
                                    return
                                }

                                guard let user = result?.user else { return }

                                UserService.shared.saveUserData(
                                    uid: user.uid,
                                    firstName: firstName,
                                    lastName: lastName,
                                    nickname: nickname,
                                    email: email,
                                    image: profileImage
                                ) { error in
                                    if let error = error {
                                        print("Erreur lors de l'enregistrement Firestore : \(error.localizedDescription)")
                                    } else {
                                        print("Enregistrement Firestore réussi")
                                        do {
                                            try Auth.auth().signOut()
                                            print("Déconnexion après création du compte")
                                            presentationMode.wrappedValue.dismiss()
                                        } catch {
                                            print("Erreur lors de la déconnexion : \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        Text("S'inscrire")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(fieldsAreValid() ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(!fieldsAreValid())
                }
            }
            .navigationBarItems(trailing: Button("Annuler") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func fieldsAreValid() -> Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               password == confirmPassword &&
               !firstName.isEmpty &&
               !lastName.isEmpty &&
               !nickname.isEmpty
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(authService: AuthenticationService())
    }
}

