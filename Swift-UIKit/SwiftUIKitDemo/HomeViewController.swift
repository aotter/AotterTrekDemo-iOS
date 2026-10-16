import UIKit

final class HomeViewController: UITableViewController {

    private struct Row {
        let title: String
        let makePage: () -> UIViewController
    }

    private let sections: [(title: String, rows: [Row])] = [
        ("AotterTrek", [
            Row(title: "Native ad") { TrekNativeViewController() },
            Row(title: "Native ads in a feed") { TrekFeedViewController() },
            Row(title: "Banner ad") { TrekBannerViewController() },
        ]),
        ("AdMob mediation", [
            Row(title: "Native ad") { AdMobNativeViewController() },
            Row(title: "Native ads in a feed") { AdMobFeedViewController() },
            Row(title: "Banner ad") { AdMobBannerViewController() },
        ]),
        ("Tracker", [
            Row(title: "Report what the user does") { TrackerViewController() },
        ]),
    ]

    init() {
        super.init(style: .insetGrouped)
        title = "AotterTrek Demo"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Row")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Row", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section].rows[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        let page = row.makePage()
        page.title = row.title
        navigationController?.pushViewController(page, animated: true)
    }
}
