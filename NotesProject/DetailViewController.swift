//
//  DetailViewController.swift
//  NotesProject
//
//  Created by Olha Pylypiv on 02.05.2024.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet var noteTextView: UITextView!
    var note: Note?
    var notes: [Note]?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        noteTextView.text = note?.body
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveNote))
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteNote))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareNote))
        
        navigationItem.rightBarButtonItems = [saveButton, deleteButton, shareButton]
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func saveNote() {
        guard !noteTextView.text.isEmpty else { return }
        
        let newNote = Note(title: String(noteTextView.text.prefix(25) + "..."), body: noteTextView.text)
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let jsonURL = documentsDirectory.appendingPathComponent("notesFile.json")
            
            do {
                var existingNotes = Notes(notes: [])
                
                // Check if the file exists before attempting to load existing notes
                if FileManager.default.fileExists(atPath: jsonURL.path) {
                    let existingData = try Data(contentsOf: jsonURL)
                    guard !existingData.isEmpty else {
                        // File is empty, create a new Notes object with the new note
                        let newNotes = Notes(notes: [newNote])
                        let jsonData = try JSONEncoder().encode(newNotes)
                        try jsonData.write(to: jsonURL)
                        print("Note saved successfully.")
                        return
                    }
                    existingNotes = try JSONDecoder().decode(Notes.self, from: existingData)
                }
                
                // Append the new note to the existing notes
                existingNotes.notes.append(newNote)
                
                // Encode the updated notes array
                let jsonData = try JSONEncoder().encode(existingNotes)
                
                // Write the updated JSON data back to the file
                try jsonData.write(to: jsonURL)
                notes = existingNotes.notes
                NotificationCenter.default.post(name: .didSaveNote, object: nil, userInfo: ["notes": existingNotes.notes])
                navigationController?.popViewController(animated: true)
                print("Note saved successfully.")
            } catch {
                // Handle any errors
                print("Error saving note:", error)
            }
        }
    }
    
    @objc func deleteNote() {
        let ac = UIAlertController(title: "Delete this note?", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .default) { [weak self] _ in
            guard let self = self else { return }

            if let notes = self.notes {
                let notesArray = Notes(notes: notes.filter { $0.body != self.note?.body })
                let notesDictionary = ["notes": notesArray.notes]

                do {
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let jsonURL = documentsDirectory.appendingPathComponent("notesFile.json")
                        // Encode the updated notes array
                        let jsonData = try JSONEncoder().encode(notesDictionary)
                        
                        // Write the updated JSON data back to the file
                        try jsonData.write(to: jsonURL)
                        
                        // Notify observers about the updated notes array
                        NotificationCenter.default.post(name: .didSaveNote, object: nil, userInfo: ["notes": notesArray.notes])
                        
                        // Pop the view controller
                        self.navigationController?.popViewController(animated: true)
                        print("Note deleted successfully.")
                    }
                } catch {
                    print("Error deleting the note: \(error)")
                }
            }
        })
        present(ac, animated: true)
    }
    
    @objc func shareNote() {
        guard let noteToShare = note?.body else {return}
        let vc = UIActivityViewController(activityItems: [noteToShare], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.last
        present(vc, animated: true)
    }
    
    @objc func adjustKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            noteTextView.contentInset = .zero
        } else {
            noteTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        noteTextView.scrollIndicatorInsets = noteTextView.contentInset
        
        let selectedRange = noteTextView.selectedRange
        noteTextView.scrollRangeToVisible(selectedRange)
    }
}
