/**
 *  BulletinBoard
 *  Copyright (c) 2017 Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BulletinBoard

/**
 * An item that displays a choice with two buttons.
 *
 * This item demonstrates how to create a bulletin item with a custom interface, and changing the
 * next item based on user interaction.
 */

class PetSelectorBulletinPage: BulletinItem {

    /**
     * The object managing the item. Required by the `BulletinItem` protocol.
     *
     * You can use it to switch to the previous/next item or dismiss the bulletin.
     *
     * Always check if it is nil, as the manager will unset this value when the current item changes.
     */

    weak var manager: BulletinManager?

    /**
     * Whether the item can be dismissed. If you set this value to `true`, the user will be able
     * to dimiss the bulletin by tapping outside the card.
     *
     * You should set it to true for optional items or if it is the last in a configuration sequence.
     */

    var isDismissable: Bool = false

    /**
     * The block of code to execute when the bulletin item is dismissed. This is called when the bulletin
     * is moved out of view.
     *
     * You can leave it `nil` if `isDismissable` is set to false.
     *
     * - parameter item: The item that is being dismissed. When calling `dismissalHandler`, the manager
     * passes a reference to `self` so you don't have to manage weak references yourself.
     */

    public var dismissalHandler: ((_ item: BulletinItem) -> Void)? = nil

    /**
     * The item to display after this one. You can modify it at runtime based on user selection for
     * instance.
     *
     * Here, we will change the time based on the pet chosen by the user.
     */

    var nextItem: BulletinItem?

    /**
     * An object that creates standard inteface components.
     */

    let appearance = BulletinAppearance()


    // MARK: - Interface Elements

    private var catButtonContainer: UIButton!
    private var dogButtonContainer: UIButton!
    private var saveButtonContainer: UIButton!

    private var selectionFeedbackGenerator = SelectionFeedbackGenerator()

    // MARK: - BulletinItem

    /**
     * Called by the manager when the item is about to be removed from the bulletin.
     *
     * Use this function as an opportunity to do any clean up or remove tap gesture recognizers /
     * button targets from your views to avoid retain cycles.
     */

    func tearDown() {
        catButtonContainer?.removeTarget(self, action: nil, for: .touchUpInside)
        dogButtonContainer?.removeTarget(self, action: nil, for: .touchUpInside)
        saveButtonContainer?.removeTarget(self, action: nil, for: .touchUpInside)
    }

    /**
     * Called by the manager to build the view hierachy of the bulletin.
     *
     * We need to return the view in the order we want them displayed. You should use a
     * `BulletinInterfaceFactory` to generate standard views, such as title labels and buttons.
     */

    func makeArrangedSubviews() -> [UIView] {

        var arrangedSubviews = [UIView]()
        let favoriteTabIndex = BulletinDataSource.favoriteTabIndex

        // Create the interface builder

        /**
         * An interface builder allows you to create standard interface components using a customized
         * appearance.
         *
         * You should always use it to generate title and description labels, and action and alternative
         * buttons.
         */

        let interfaceBuilder = BulletinInterfaceBuilder(appearance: appearance)

        // Title Label

        let title = "Choose your Favorite"
        let titleLabel = interfaceBuilder.makeTitleLabel(text: title)
        arrangedSubviews.append(titleLabel)

        // Description Label

        appearance.shouldUseCompactDescriptionText = false // The text is short, so we don't need to display it with a smaller font
        let descriptionLabel = interfaceBuilder.makeDescriptionLabel()
        descriptionLabel.text = "Your favorite pets will appear when you open the app."
        arrangedSubviews.append(descriptionLabel)

        // Pets Stack

        // We add choice cells to a group stack because they need less spacing
        let petsStack = interfaceBuilder.makeGroupStack(spacing: 16)
        arrangedSubviews.append(petsStack)

        // Cat Button

        let catButtonContainer = createChoiceCell(emoji: "🐱", title: "Cats", isSelected: favoriteTabIndex == 0)
        catButtonContainer.addTarget(self, action: #selector(catButtonTapped), for: .touchUpInside)
        petsStack.addArrangedSubview(catButtonContainer)

        self.catButtonContainer = catButtonContainer

        // Dog Button

        let dogButtonContainer = createChoiceCell(emoji: "🐶", title: "Dogs", isSelected: favoriteTabIndex == 1)
        dogButtonContainer.addTarget(self, action: #selector(dogButtonTapped), for: .touchUpInside)
        petsStack.addArrangedSubview(dogButtonContainer)

        self.dogButtonContainer = dogButtonContainer

        // Save Button

        let saveButtonContainer = interfaceBuilder.makeActionButton(title: "Save")
        saveButtonContainer.button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        arrangedSubviews.append(saveButtonContainer)

        return arrangedSubviews

    }

    // MARK: - Custom Views

    /**
     * Creates a custom choice cell.
     */

    func createChoiceCell(emoji: String, title: String, isSelected: Bool) -> UIButton {

        let button = UIButton(type: .system)
        button.setTitle(emoji + " " + title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.contentHorizontalAlignment = .center
        button.accessibilityLabel = title

        if isSelected {
            button.accessibilityTraits |= UIAccessibilityTraitSelected
        } else {
            button.accessibilityTraits &= ~UIAccessibilityTraitSelected
        }

        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2

        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.heightAnchor.constraint(equalToConstant: 55).isActive = true

        let buttonColor = isSelected ? appearance.actionButtonColor : .lightGray
        button.layer.borderColor = buttonColor.cgColor
        button.setTitleColor(buttonColor, for: .normal)
        button.layer.borderColor = buttonColor.cgColor

        if isSelected {
            nextItem = PetSelectorValidationBulletinPage(animalName: title.lowercased(), animalEmoji: emoji)
        }

        return button

    }

    // MARK: - Touch Events

    /// Called when the cat button is tapped.
    @objc func catButtonTapped() {

        // Play haptic feedback

        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // Update UI

        let catButtonColor = appearance.actionButtonColor
        catButtonContainer?.layer.borderColor = catButtonColor.cgColor
        catButtonContainer?.setTitleColor(catButtonColor, for: .normal)
        catButtonContainer?.accessibilityTraits |= UIAccessibilityTraitSelected

        let dogButtonColor = UIColor.lightGray
        dogButtonContainer?.layer.borderColor = dogButtonColor.cgColor
        dogButtonContainer?.setTitleColor(dogButtonColor, for: .normal)
        dogButtonContainer?.accessibilityTraits &= ~UIAccessibilityTraitSelected

        // Send a notification to inform observers of the change

        NotificationCenter.default.post(name: .FavoriteTabIndexDidChange,
                                        object: self,
                                        userInfo: ["Index": 0])

        // Set the next item

        nextItem = PetSelectorValidationBulletinPage(animalName: "cats", animalEmoji: "🐱")

    }

    /// Called when the dog button is tapped.
    @objc func dogButtonTapped() {

        // Play haptic feedback

        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // Update UI

        let catButtonColor = UIColor.lightGray
        catButtonContainer?.layer.borderColor = catButtonColor.cgColor
        catButtonContainer?.setTitleColor(catButtonColor, for: .normal)
        catButtonContainer?.accessibilityTraits &= ~UIAccessibilityTraitSelected

        let dogButtonColor = appearance.actionButtonColor
        dogButtonContainer?.layer.borderColor = dogButtonColor.cgColor
        dogButtonContainer?.setTitleColor(dogButtonColor, for: .normal)
        dogButtonContainer?.accessibilityTraits |= UIAccessibilityTraitSelected

        // Send a notification to inform observers of the change

        NotificationCenter.default.post(name: .FavoriteTabIndexDidChange,
                                        object: self,
                                        userInfo: ["Index": 1])

        // Set the next item

        nextItem = PetSelectorValidationBulletinPage(animalName: "dogs", animalEmoji: "🐶")

    }

    /// Called when the save button is tapped.
    @objc func saveButtonTapped() {

        // Play haptic feedback
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // Ask the manager to present the next item.
        manager?.displayNextItem()

    }

}

/**
 * A bulletin page that allows the user to validate its selection
 *
 * This item demonstrates popping to the previous item.
 */

class PetSelectorValidationBulletinPage: BulletinItem {

    weak var manager: BulletinManager? = nil
    var isDismissable: Bool = false
    var dismissalHandler: ((BulletinItem) -> Void)? = nil
    var nextItem: BulletinItem?

    let appearance = BulletinAppearance()

    // MARK: - Configuration

    let animalName: String
    let animalEmoji: String

    init(animalName: String, animalEmoji: String) {
        self.animalName = animalName
        self.animalEmoji = animalEmoji
    }

    private var selectionFeedbackGenerator = SelectionFeedbackGenerator()
    private var successFeedbackGenerator = SuccessFeedbackGenerator()

    // MARK: - Interface Elements

    private var validateButton: UIButton?
    private var backButton: UIButton?

    // MARK: - BulletinItem

    func makeArrangedSubviews() -> [UIView] {

        var arrangedSubviews = [UIView]()
        let interfaceBuilder = BulletinInterfaceBuilder(appearance: appearance)

        // Title Label

        let title = "Choose your Favorite"
        let titleLabel = interfaceBuilder.makeTitleLabel(text: title)
        arrangedSubviews.append(titleLabel)

        // Emoji

        let emojiLabel = UILabel()
        emojiLabel.numberOfLines = 1
        emojiLabel.textAlignment = .center
        emojiLabel.adjustsFontSizeToFitWidth = true
        emojiLabel.font = UIFont.systemFont(ofSize: 66)
        emojiLabel.text = animalEmoji
        emojiLabel.isAccessibilityElement = false

        arrangedSubviews.append(emojiLabel)

        // Description Label

        let descriptionLabel = interfaceBuilder.makeDescriptionLabel()
        descriptionLabel.text = "You chose \(animalName) as your favorite animal type. Are you sure?"
        arrangedSubviews.append(descriptionLabel)

        // Validate Button

        let buttonsStack = interfaceBuilder.makeGroupStack()
        arrangedSubviews.append(buttonsStack)

        let validateButton = interfaceBuilder.makeActionButton(title: "Validate")
        validateButton.button.addTarget(self, action: #selector(validateButtonTapped), for: .touchUpInside)
        self.validateButton = validateButton.button
        buttonsStack.addArrangedSubview(validateButton)

        // Back Button

        let backButton = interfaceBuilder.makeAlternativeButton(title: "Change")
        buttonsStack.addArrangedSubview(backButton)

        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.backButton = backButton

        return arrangedSubviews

    }

    // MARK: - Touch Events

    @objc private func validateButtonTapped() {

        // > Play Haptic Feedback

        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // > Display the loading indicator

        manager?.displayActivityIndicator()

        // > Wait for a "task" to complete before displaying the next item

        let delay = DispatchTime.now() + .seconds(2)

        DispatchQueue.main.asyncAfter(deadline: delay) {

            // Play success haptic feedback

            self.successFeedbackGenerator.prepare()
            self.successFeedbackGenerator.success()

            // Display next item

            self.nextItem = BulletinDataSource.makeCompletionPage()
            self.manager?.displayNextItem()

        }

    }

    func tearDown() {
        validateButton?.removeTarget(self, action: nil, for: .touchUpInside)
        backButton?.removeTarget(self, action: nil, for: .touchUpInside)
        validateButton = nil
        backButton = nil
    }

    @objc private func backButtonTapped() {

        // Play selection haptic feedback

        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()

        // Display previous item

        manager?.popItem()

    }

}

