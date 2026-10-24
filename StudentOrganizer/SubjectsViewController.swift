import UIKit
import CoreData

/// First screen: the list of subjects. Root of the UINavigationController.
class SubjectsViewController: UITableViewController {

    // MARK: - Properties
    private var subjects: [Subject] = []
    private let context = CoreDataStack.shared.context

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Subjects"
        tableView.backgroundColor = Theme.background
        tableView.separatorStyle = .none   // rows are separate soft cards instead
    }

    // Runs every time the screen appears, so the list is always up to date
    // (for example, after returning from the Tasks screen where counts may change).
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSubjects()
    }

    // MARK: - Core Data
    private func loadSubjects() {
        let request: NSFetchRequest<Subject> = Subject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            subjects = try context.fetch(request)
        } catch {
            print("Could not fetch subjects: \(error)")
            subjects = []
        }
        updateEmptyState()
        tableView.reloadData()
    }

    /// Shows a hint behind the table when there are no subjects.
    private func updateEmptyState() {
        tableView.backgroundView = subjects.isEmpty
            ? emptyStateLabel("No subjects yet.\nTap + to add one.") : nil
    }

    // MARK: - Actions
    @IBAction func addSubjectTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Subject",
                                      message: "Enter the name of the subject.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., Mobile Application Development 2"
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let saveAction = UIAlertAction(title: "Save", style: .default) {
            [weak self, weak alert] _ in
            // guard: stop quietly if the name is empty (never force-unwrap user input)
            guard let self = self,
                  let name = alert?.textFields?.first?.text?
                      .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            let subject = Subject(context: self.context)   // create a new row
            subject.name = name
            subject.createdAt = Date()
            CoreDataStack.shared.save()                    // write it to the database
            self.loadSubjects()
        }
        alert.addAction(saveAction)
        present(alert, animated: true)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubjectCell",
                                                 for: indexPath)
        let subject = subjects[indexPath.row]
        // subject.tasks is an NSSet of TaskItem objects (the relationship in the model).
        let allTasks = subject.tasks as? Set<TaskItem> ?? []
        let pendingCount = allTasks.filter { !$0.isDone }.count

        var content = cell.defaultContentConfiguration()
        content.text = subject.name ?? "Untitled subject"
        content.secondaryText = "\(pendingCount) pending task(s)"
        content.textProperties.color = Theme.textPrimary
        content.secondaryTextProperties.color = Theme.textSecondary
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 18, leading: 16, bottom: 18, trailing: 8)
        cell.applySoftCardStyle()
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Table view delegate
    // Swipe left on a row to delete it.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // The Cascade delete rule also deletes this subject's tasks and notes.
        context.delete(subjects[indexPath.row])
        CoreDataStack.shared.save()
        subjects.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        updateEmptyState()
    }

    // Open the tapped subject.
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // sender: the Subject that was tapped. prepare(for:sender:) receives it.
        performSegue(withIdentifier: "ShowTasksSegue",
                     sender: subjects[indexPath.row])
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowTasksSegue",
              let destination = segue.destination as? TasksViewController,
              let subject = sender as? Subject else { return }
        destination.subject = subject   // hand the chosen subject to the next screen
    }
}
