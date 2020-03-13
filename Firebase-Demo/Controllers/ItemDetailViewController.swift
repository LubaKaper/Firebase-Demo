//
//  ItemDetailViewController.swift
//  Firebase-Demo
//
//  Created by Liubov Kaper  on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ItemDetailViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var commentTextfield: UITextField!
    
    private var item: Item
    
    private var  databaseService = DatabaseService()
    
    // for keyboard handling
    private var originalValueforConstraint: CGFloat = 0
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissKeyboard))
        return gesture
    }()
    
    private var listener: ListenerRegistration?
    
    private var comments = [Comment]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, h:mm a"
        return formatter
    }()
    
    private var isFavorite = false {
        didSet {
            if isFavorite {
                navigationItem.rightBarButtonItem?.image = UIImage(systemName: "heart.fill")
            } else {
                navigationItem.rightBarButtonItem?.image = UIImage(systemName: "heart")
            }
        }
    }
    
    init?(coder: NSCoder, item: Item) {
        self.item = item
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = item.itemName
       // navigationItem.largeTitleDisplayMode = 
        // setting up HeaderView of tableView programmatically and using initalizer
        tableView.tableHeaderView = HeaderView(imageURL: item.imageURL)
        
        
        // for keyboard handling
        originalValueforConstraint = containerBottomConstraint.constant
         commentTextfield.delegate = self
        
        view.addGestureRecognizer(tapGesture)
        tableView.dataSource = self
        
        // TODO: refactor code in viewDidLoad(make less clutterd
        updateUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        registerKeyboardNotifications()
        
        listener = Firestore.firestore().collection(DatabaseService.itemsCollection).document(item.itemId).collection(DatabaseService.commentsCollection).addSnapshotListener({ [weak self](snapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Try Again", message: error.localizedDescription)
                }
            } else if let snapshot = snapshot {
                // create comments using dictionary iniotializer from Comment model
                let comments = snapshot.documents.map { Comment($0.data())}
                self?.comments = comments.sorted { $0.commentDate.dateValue() > $1.commentDate.dateValue()}
            }
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        unregisterKeyboardNotification()
        listener?.remove()
    }
    
    private func updateUI() {
        // check if item is a favorite and update hart icon accordingly
        databaseService.isItemInFAvorites(item: item) { [weak self](result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Try again", message: error.localizedDescription)
                }
            case .success(let success):
                if success { // true
                    self?.isFavorite = true
                    
                } else {
                    self?.isFavorite = false
                }
            }
        }
    }
    

    @IBAction func sendButtonPressed(_ sender: UIButton) {
        dismissKeyboard()
        // TODO: Firebase: add comment to the comments collection on this item
        guard let commentText = commentTextfield.text,
            !commentText.isEmpty else {
                showAlert(title: "Missing Fields", message: "A comment is required")
                return
        }
        // post to firebase
        postComment(text: commentText)
    }
    
    private func postComment(text: String) {
        databaseService.postComment(item: item, comment: text) { [weak self](result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Try Again", message: error.localizedDescription)
                }
            case .success:
                DispatchQueue.main.async {
                    self?.showAlert(title: "Comment Posted", message: nil)
                }
            }
        }
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    private func unregisterKeyboardNotification() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
               NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        print(notification.userInfo ?? "") // infokeys from the userInfo
        guard let keyboardFrame = notification.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
            return
        }
        // adjust the container bottom constraint
        containerBottomConstraint.constant = -(keyboardFrame.height - view.safeAreaInsets.bottom)
    }
    
   @objc private func keyboardWillHide(_ notification: Notification) {
           
       }
    
    @objc private func dismissKeyboard() {
        containerBottomConstraint.constant = originalValueforConstraint
        commentTextfield.resignFirstResponder()
    }
    
    // adds and removes from favorites
    @IBAction func favoriteButtonPressed(_ sender: UIBarButtonItem) {
        
        if isFavorite {
            databaseService.removeFromFavorites(item: item) { [weak self](result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Failed to remove favorite", message: error.localizedDescription)
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Item rermoved", message: nil)
                        self?.isFavorite = false
                    }
                }
            }
            
        } else {
            databaseService.addToFavorites(item: item) { [weak self](result) in
                       switch result {
                       case .failure(let error):
                           DispatchQueue.main.async {
                               self?.showAlert(title: "Favoriting Error", message: error.localizedDescription)
                           }
                       case .success:
                           DispatchQueue.main.async {
                               self?.showAlert(title: "Item Favorited", message: nil)
                            // this will change icon heart(also updateUI is needed!
                            self?.isFavorite = true
                           }
                       }
                   }
        }
        
    }
    
}

extension ItemDetailViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        let comment = comments[indexPath.row]
        let dateString = dateFormatter.string(from: comment.commentDate.dateValue())
        
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = "@" + comment.commentedBy + " " + dateString
        return cell
    }
    
    
}

extension ItemDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}
