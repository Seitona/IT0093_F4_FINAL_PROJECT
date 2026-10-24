import UIKit
import CoreData

/// Lists the tasks of one subject; entry point to the Task Form and Notes grid.
class TasksViewController: UITableViewController {

    // MARK: - Properties
    /// Set by SubjectsViewController in prepare(for:sender:).
    var subject: Subject?
    private var tasks: [TaskItem] = []
    private let context = CoreDataStack.shared.context

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = subject?.name
        tableView.backgroundColor = Theme.background
        tableView.separatorStyle = .none   // rows are separate soft cards instead
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()   // refresh after returning from the Task Form
    }

    // MARK: - Core Data
    private func loadTasks() {
        guard let subject = subject else { return }
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // Only the tasks that belong to THIS subject.
        request.predicate = NSPredicate(format: "subject == %@", subject)
        // Unfinished tasks first, then the earliest due date first.
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Could not fetch tasks: \(error)")
            tasks = []
        }
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.") : nil
        tableView.reloadData()
    }

    // MARK: - Actions
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        // sender: nil means "no existing task", so the form opens in "add" mode.
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)
        let task = tasks[indexPath.row]
        // Compact format (no year / "at") so the subtitle fits on one line next to the switch.
        let dueText = task.dueDate?.formatted(
            .dateTime.month(.abbreviated).day().hour().minute()) ?? "no due date"

        var content = cell.defaultContentConfiguration()
        let titleText = task.title ?? "Untitled task"
        if task.isDone {
            // Finished tasks are struck through and grayed out so pending work stands out.
            content.attributedText = NSAttributedString(string: titleText, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: Theme.textSecondary
            ])
        } else {
            content.text = titleText
            content.textProperties.color = Theme.textPrimary
        }
        content.secondaryText = "Due \(dueText) - \(priorityName(for: task.priority))"
        content.secondaryTextProperties.color = Theme.textSecondary

        // Colored dot = priority (green Low, yellow Medium, red High).
        content.image = UIImage(systemName: "circle.fill")
        content.imageProperties.tintColor = Theme.priorityColor(for: task.priority)
        content.imageProperties.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(pointSize: 14)
        content.imageToTextPadding = 12
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16, leading: 16, bottom: 16, trailing: 8)

        cell.applySoftCardStyle()
        cell.contentConfiguration = content
        cell.accessoryType = .none
        cell.accessoryView = makeCompletedSwitch(for: task)
        return cell
    }

    /// The "completed" toggle shown on every row, so a task can be finished
    /// without opening the edit screen. Tapping elsewhere on the row still edits it.
    private func makeCompletedSwitch(for task: TaskItem) -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = task.isDone
        toggle.onTintColor = Theme.priorityGreen
        toggle.addAction(UIAction { [weak self, weak toggle] _ in
            guard let self = self, let toggle = toggle else { return }
            task.isDone = toggle.isOn
            CoreDataStack.shared.save()
            // Short delay lets the switch finish animating before the row re-sorts.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.loadTasks() }
        }, for: .valueChanged)
        return toggle
    }

    /// Priority is stored as a number in Core Data (0 Low, 1 Medium, 2 High).
    private func priorityName(for value: Int16) -> String {
        switch value {
        case 0:  return "Low"
        case 2:  return "High"
        default: return "Medium"
        }
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Pass the tapped task so the form opens in "edit" mode.
        performSegue(withIdentifier: "ShowTaskFormSegue",
                     sender: tasks[indexPath.row])
    }

    // Swipe right: mark done / undo.
    override func tableView(_ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        let title = task.isDone ? "Undo" : "Done"
        let action = UIContextualAction(style: .normal, title: title) {
            [weak self] _, _, completion in
            task.isDone.toggle()
            CoreDataStack.shared.save()
            self?.loadTasks()   // re-sort so finished tasks move to the bottom
            completion(true)
        }
        action.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }

    // Swipe left: delete.
    override func tableView(_ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.context.delete(self.tasks[indexPath.row])
            CoreDataStack.shared.save()
            self.loadTasks()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowTaskFormSegue":
            guard let destination = segue.destination as? TaskFormViewController
            else { return }
            destination.subject = subject
            destination.taskToEdit = sender as? TaskItem   // nil when adding a new task
        case "ShowNotesSegue":
            guard let destination = segue.destination as? NotesViewController
            else { return }
            destination.subject = subject
        default:
            break
        }
    }
}
