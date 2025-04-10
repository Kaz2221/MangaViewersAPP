import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI
import SDWebImageSwiftUI

struct EditProfileView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var imageUrl: String
    @Binding var nickname: String

    @State private var newFirstName: String = ""
    @State private var newLastName: String = ""
    @State private var newNickname: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Photo de profil")) {
                HStack {
                    Spacer()
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }

                PhotosPicker("Choisir une nouvelle photo", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
            }

            Section(header: Text("Informations personnelles")) {
                TextField("Prénom", text: $newFirstName)
                TextField("Nom", text: $newLastName)
                TextField("Surnom", text: $newNickname)
            }

            Button("Enregistrer") {
                saveChanges()
            }
        }
        .navigationTitle("Modifier le profil")
        .onAppear {
            newFirstName = firstName
            newLastName = lastName
            newNickname = nickname
        }
    }

    private func saveChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var updates: [String: Any] = [
            "firstName": newFirstName,
            "lastName": newLastName,
            "nickname": newNickname
        ]

        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.5) {
            let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
            storageRef.putData(imageData, metadata: nil) { _, error in
                if error == nil {
                    storageRef.downloadURL { url, error in
                        if let url = url {
                            updates["imageUrl"] = url.absoluteString
                            updateFirestoreData(uid: uid, updates: updates)
                        }
                    }
                }
            }
        } else {
            updateFirestoreData(uid: uid, updates: updates)
        }
    }

    private func updateFirestoreData(uid: String, updates: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(updates) { error in
            if error == nil {
                firstName = newFirstName
                lastName = newLastName
                nickname = newNickname
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

