//
//  ViewController.swift
//  NotesProject
//
//  Created by Olha Pylypiv on 02.05.2024.
//

import UIKit

class ViewController: UITableViewController {
    var notes = [Note]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notes"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let fileBundleURL = Bundle.main.url(forResource: "notesFile", withExtension: "json")!
        let docDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("notesFile.json")
        
        if FileManager.default.fileExists(atPath: docDirectoryURL.path) {
            // Handle the case where the file already exists
                do {
                    let jsonData = try Data(contentsOf: docDirectoryURL)
                    print("File already exists at \(docDirectoryURL)")
                    print("JSON data count is", jsonData.count)
                    
                    // Attempt to decode the JSON data into Notes object
                    let jsonNotes = try JSONDecoder().decode(Notes.self, from: jsonData)
                    notes = jsonNotes.notes
                    tableView.reloadData()
                } catch {
                    print("Error decoding JSON data:", error)
                }
        } else {
            do {
                let jsonData = try Data(contentsOf: fileBundleURL)
                try jsonData.write(to: docDirectoryURL)
                print("File copied successfully to \(docDirectoryURL)")
                
                // Now try to load and decode the JSON data from the copied file
                let copiedJsonData = try Data(contentsOf: docDirectoryURL)
                print("Copied JSON Data Size:", copiedJsonData.count)
                
                let jsonNotes = try JSONDecoder().decode(Notes.self, from: copiedJsonData)
                notes = jsonNotes.notes
                tableView.reloadData()
            } catch {
                let firstNote = Note(title: "Create your new note", body: "This is where you can write your notes.")
                notes = [firstNote]
                print("Error loading JSON data:", error)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidSaveNoteNotification(_:)), name: .didSaveNote, object: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Note", for: indexPath)
        let note = notes[indexPath.row]
        cell.textLabel?.text = note.title
        cell.detailTextLabel?.text = note.body
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            vc.note = notes[indexPath.row]
            vc.notes = notes
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func addNewNote() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {  
            vc.notes = notes
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func handleDidSaveNoteNotification(_ notification: Notification) {
        print("didSaveNote notification received.")
        guard let userInfo = notification.userInfo,
              let savedNotes = userInfo["notes"] as? [Note] else {
            return
        }
        notes = savedNotes
        tableView.reloadData()
    }
}

extension Notification.Name {
    static let didSaveNote = Notification.Name("didSaveNote")
}
