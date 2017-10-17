//
//  PCActionSheetViewController.swift
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 16/10/2017.
//
import UIKit

@objc public class HeaderViewParams: NSObject {
    var fileIcon: UIImage
    var fileName: String
    var filePath: String
    
    init(fileIcon: UIImage, fileName: String, filePath: String) {
        self.fileIcon = fileIcon
        self.fileName = fileName
        self.filePath = filePath
    }
}

@objc public class PCActionSheetViewController: UIViewController {
    
    var actionsTableView: UITableView! = nil
    var bottomButton: UIButton! = nil
    var actions: [PCAction] = []
    var bottomAction:PCAction! = nil
    
    private var tableViewHeightConstraint: NSLayoutConstraint! = nil
    private var tableViewWidthConstraint: NSLayoutConstraint! = nil
    
    var backgroundView: UIView! = nil
    
    var headerParams:HeaderViewParams?
    var headerHeigh : Int = 90
    var separator: UIView = UIView(frame: .zero)
    
    private var actionSheetTransitioningDelegate: UIViewControllerTransitioningDelegate?
    
    
    // MARK: Initializers
    
    public init(transitioningDelegate: UIViewControllerTransitioningDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.setupViews()
        self.setup(transitioningDelegate)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupViews()
        self.setup(PCTransitioningDelegate())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
        self.setup(PCTransitioningDelegate())
        
    }
    
    open func setup(_ transitioningDelegate: UIViewControllerTransitioningDelegate) {
        self.modalPresentationStyle = .custom
        self.actionSheetTransitioningDelegate = transitioningDelegate
        self.transitioningDelegate = self.actionSheetTransitioningDelegate
    }
    
    open func setupViews() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenRotationChangesNotifications()
        self.actionsTableView = UITableView(frame: .zero)
        self.bottomButton = UIButton(frame: .zero)
        self.backgroundView = UIView(frame: .zero)
        
        
        self.bottomButton.translatesAutoresizingMaskIntoConstraints = false;
        self.actionsTableView.translatesAutoresizingMaskIntoConstraints = false;
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.addSubview(self.bottomButton)
        }
        
        self.view.addSubview(self.backgroundView)
        let backgroundGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.backgrounViewTouched))
        self.backgroundView.addGestureRecognizer(backgroundGestureRecognizer)
        self.setBackgroundViewConstraints()
        
        self.view.addSubview(self.actionsTableView)
        self.bottomButton.backgroundColor = UIColor.white
        self.actionsTableView.backgroundColor = UIColor.white
        self.setRoundedCornerRadius()
        self.actionsTableView.separatorStyle = .singleLine
        self.actionsTableView.separatorColor = .lightGray
        self.actionsTableView.showsVerticalScrollIndicator = false
        self.actionsTableView.bounces = false
        
        self.actionsTableView.delegate = self
        self.actionsTableView.dataSource = self
        
        
        self.configureBottomButton()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeListenRotationChangesNotifications()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.setIpadContraints()
        }else {
            self.setIphoneConstraints()
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @objc public func setHeaderViewParams(icon: UIImage, name: String, path: String) {
        self.headerParams = HeaderViewParams(fileIcon: icon, fileName: name, filePath: path)
        
        self.calculateHeaderHeight()
    }
    
    //MARK: Constraints
    private func calculateHeaderHeight(){
        let name = self.headerParams?.fileName
        
        let lines = (name?.characters.count)! / 28
        
        let min = 90
        let max = 150
        
        var newHeight = min + lines * 10
        
        if newHeight > max {
            newHeight = max
        }
        
        self.headerHeigh = newHeight
        
    }
    
    public func setBackgroundViewConstraints() -> Void {
        
        let margins = view.layoutMarginsGuide
        self.backgroundView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -20.0).isActive = true
        self.backgroundView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: +20.0).isActive = true
        self.backgroundView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 0.0).isActive = true
        self.backgroundView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0.0).isActive = true
    }
    
    public func setIphoneConstraints() -> Void{
        
        let margins = view.layoutMarginsGuide
        self.bottomButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.bottomButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.bottomButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -16.0).isActive = true
        self.bottomButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        
        let bottomButtonMargins = self.bottomButton.layoutMarginsGuide
        self.actionsTableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.actionsTableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.actionsTableView.bottomAnchor.constraint(equalTo: bottomButtonMargins.topAnchor, constant: -16.0).isActive = true
        
        if self.tableViewHeightConstraint != nil{
            self.tableViewHeightConstraint.isActive = false;
        }
        self.tableViewHeightConstraint = NSLayoutConstraint(item: self.actionsTableView, attribute: .height, relatedBy: .equal, toItem: nil,  attribute: .notAnAttribute, multiplier: 1.0, constant: self.heightForTableView())
        self.tableViewHeightConstraint.isActive = true;
    }
    
    public func setIpadContraints() -> Void {
        self.actionsTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        self.actionsTableView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
        
        if self.tableViewHeightConstraint != nil{
            self.tableViewHeightConstraint.isActive = false;
        }
        
        if self.tableViewWidthConstraint != nil{
            self.tableViewWidthConstraint.isActive = false;
        }
        
        self.tableViewHeightConstraint = NSLayoutConstraint(item: self.actionsTableView, attribute: .height, relatedBy: .equal, toItem: nil,  attribute: .notAnAttribute, multiplier: 1.0, constant: self.heightForTableView())
        
        self.tableViewWidthConstraint = NSLayoutConstraint(item: self.actionsTableView, attribute: .width, relatedBy: .equal, toItem: nil,  attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(self.view.bounds.width / 2))
        
        self.tableViewHeightConstraint.isActive = true;
        self.tableViewWidthConstraint.isActive = true;
        
    }
    
    private func heightForTableView() -> CGFloat {
        
        var maxTableViewHeight: CGFloat
        if  UIDevice.current.userInterfaceIdiom == .pad {
            maxTableViewHeight = self.view.bounds.size.height - 32.0
        } else {
            maxTableViewHeight = self.view.bounds.size.height - 60.0 - 32.0 - 16.0
        }
        
        var actualHeight = Double(self.actions.count) * 60.0
        
        if self.headerParams != nil {
            actualHeight = actualHeight + Double(self.headerHeigh)
        }
        
        return CGFloat(min(actualHeight, Double(maxTableViewHeight)))
    }
    
    //MARK: Notifications and handler for the rotation changes
    private func listenRotationChangesNotifications() -> Void {
        self.removeListenRotationChangesNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func removeListenRotationChangesNotifications() -> Void {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange , object: nil)
    }
    
    public func orientationChanged() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.setIpadContraints()
        }else {
            self.setIphoneConstraints()
        }
    }
    
    //MARK: Style
    private func setRoundedCornerRadius() {
        self.bottomButton.layer.cornerRadius = 10
        self.actionsTableView.layer.cornerRadius = 10
    }
    
    public func addAction(action: PCAction) -> Void {
        actions.append(action)
    }
    
    public func setBottomAction(action: PCAction) {
        self.bottomAction = action
    }
    
    private func configureBottomButton() {
        self.bottomButton.setTitleColor(UIColor.defaultActionSheetCell(), for: .normal)
        self.bottomButton.titleLabel?.font = UIFont(name: "SourceSansPro-Semibold", size: UIFont.buttonFontSize)
        
        self.bottomButton.setTitle("Cancel", for: .normal)
        self.bottomButton.addTarget(self, action: #selector(self.dismissActionSheet), for: .touchUpInside)
    }
    
    @objc private func dismissActionSheet() {
        self.bottomAction.action()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func backgrounViewTouched() {
        self.dismissActionSheet()
    }
    
    public func setHeaderView(header: UIView) {
        self.actionsTableView.tableHeaderView = header
    }
}

extension PCActionSheetViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard self.headerParams != nil else {
            return 0
        }
        
        return CGFloat(self.headerHeigh)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard self.headerParams != nil else {
            return nil
        }
        
        let header: UIView = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.actionsTableView.bounds.width), height: self.headerHeigh))
        
        let fileIconImageView = UIImageView(frame: .zero)
        fileIconImageView.translatesAutoresizingMaskIntoConstraints = false
        fileIconImageView.image = self.headerParams!.fileIcon
        fileIconImageView.contentMode = .scaleAspectFit
        header.addSubview(fileIconImageView)
        
        let fileNameLabel = UILabel(frame:.zero)
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.text = self.headerParams!.fileName
        fileNameLabel.textColor = UIColor(red: 90/255, green: 105/255, blue: 120/255, alpha: 1.0)
        fileNameLabel.font = UIFont(name: "SourceSansPro-Semibold", size: 15)
        fileNameLabel.adjustsFontSizeToFitWidth = true
        fileNameLabel.numberOfLines = 6
        fileNameLabel.minimumScaleFactor = 0.7
        header.addSubview(fileNameLabel)
        
        let filePathLabel = UILabel(frame:.zero)
        filePathLabel.translatesAutoresizingMaskIntoConstraints = false
        filePathLabel.text = self.headerParams!.filePath
        filePathLabel.textColor = UIColor(red: 150/255, green: 159/255, blue: 170/255, alpha: 1.0)
        fileNameLabel.font = UIFont(name: "SourceSansPro-Semibold", size: 15)
        header.addSubview(filePathLabel)
        
        self.separator = UIView(frame: .zero)
        self.separator.translatesAutoresizingMaskIntoConstraints = false
        
        self.separator.backgroundColor = .lightGray
        
        header.addSubview(separator)
        
        header.addConstraint(NSLayoutConstraint(item: fileIconImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50))
        
        header.addConstraint(NSLayoutConstraint(item: fileIconImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50))
        
        header.addConstraint(NSLayoutConstraint(item: fileIconImageView, attribute: .left, relatedBy: .equal, toItem: header, attribute: .leftMargin, multiplier: 1.0, constant: 15))
        
        header.addConstraint(NSLayoutConstraint(item: fileIconImageView, attribute: .centerY, relatedBy: .equal, toItem: header, attribute: .centerY, multiplier: 1.0, constant: 0))
        
        header.addConstraint(NSLayoutConstraint(item: fileNameLabel, attribute: .left, relatedBy: .equal, toItem: fileIconImageView, attribute: .right, multiplier: 1.0, constant: 15))
        
        header.addConstraint(NSLayoutConstraint(item: fileNameLabel, attribute: .centerY, relatedBy: .equal, toItem: header, attribute: .centerY, multiplier: 1.0, constant: -10))
        header.addConstraint(NSLayoutConstraint(item: fileNameLabel, attribute: .right, relatedBy: .equal, toItem: header, attribute: .right, multiplier: 1.0, constant: -15))
        header.addConstraint(NSLayoutConstraint(item: filePathLabel, attribute: .left, relatedBy: .equal, toItem: fileIconImageView, attribute: .right, multiplier: 1.0, constant: 15))
        
        header.addConstraint(NSLayoutConstraint(item: filePathLabel, attribute: .top, relatedBy: .equal, toItem: fileNameLabel, attribute: .bottom, multiplier: 1.0, constant: 0))
        header.addConstraint(NSLayoutConstraint(item: filePathLabel, attribute: .right, relatedBy: .equal, toItem: header, attribute: .right, multiplier: 1.0, constant: -15))
        
        header.addConstraint(NSLayoutConstraint(item: separator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1))
        
        header.addConstraint(NSLayoutConstraint(item: separator, attribute: .left, relatedBy: .equal, toItem: header, attribute: .left, multiplier: 1.0, constant: 15))
        
        header.addConstraint(NSLayoutConstraint(item: separator, attribute: .right, relatedBy: .equal, toItem: header, attribute: .right, multiplier: 1.0, constant: 10))
        
        header.addConstraint(NSLayoutConstraint(item: separator, attribute: .centerY, relatedBy: .equal, toItem: header, attribute: .centerY, multiplier: 1.0, constant: 10))
        
        header.addConstraint(NSLayoutConstraint(item: separator, attribute: .bottom, relatedBy: .equal, toItem: header, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        header.backgroundColor = UIColor.white
        
        print("LOG ---> header name lines = \(fileNameLabel.numberOfLines))")
        
        return header
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = self.actions[indexPath.row]
        self.dismiss(animated: true, completion: nil)
        action.triggerAction()
    }
    
}

extension PCActionSheetViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.actions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        let action = actions[indexPath.row]
        
        switch action.type {
        case .Destructive:
            cell.textLabel?.textColor = UIColor.destructiveActionSheetCell()
            break
        case .NormalAction:
            cell.textLabel?.textColor = UIColor.defaultActionSheetCell()
            break
        default:
            break
        }
        
        cell.textLabel?.text = action.title
        cell.textLabel?.font = UIFont(name: "SourceSansPro-Regular", size: UIFont.buttonFontSize)
        return cell
    }
}
