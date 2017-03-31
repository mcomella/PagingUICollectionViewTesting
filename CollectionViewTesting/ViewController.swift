//
//  ViewController.swift
//  CollectionViewTesting
//
//  Created by Michael Comella on 3/29/17.
//  Copyright © 2017 Michael Comella. All rights reserved.
//

/*
 We implemented UIScrollViewDelegate.scrollViewWillEndDragging to reposition the scrollView after
 dragging - this allows us to add a paging effect to the UICollectionView where the pages are smaller
 than a screen size. I believe overriding `UICollectionViewLayout.targetContentOffset(...` is largely
 the same. Here is a similar solution:
   http://blog.karmadust.com/centered-paging-with-preview-cells-on-uicollectionview/

 For completeness, an alternative solution would be to create a UICollectionView where:
 - isPagingEnabled = true
 - The UICollectionView is the size of a page, making page changes the desired size
 - clipsToBounds = false so you can see the content adjacent to the current page in the collection view
 - An additional gesture recognizer is added to handle the touches outside of the collection view.

 Our implementation is more flexible (you can scroll mulitple pages!) and less fragile (an extra gesture
 handler?).

 ---
 In order to mimic current Prox functionality, there are pieces missing: the content needs to be top-aligned
 (rather than center-aligned which is the default in UICollectionView with 1 item per line) and the
 card needs to scroll.

 In order to top-align, I believe we can override `UICollectionViewLayout.layoutAttributesForItem(at:)`,
 (from FlowLayout) setting the layout attributes such that all the items are top-aligned.

 To handle scrolling, we could overlap the entire PlaceDetailViewController with a scroll view, which
 gets a new height set each time a new item from the collection view is selected. I'm not convinced
 the overlapping scroll views will play well with each other but I'm sure someone can figure it out. :)

 ---
 If we wanted to make this into a library or post to help others (note: the post largely exists above),
 we may want to consider how this view handles header & footers in the collection view.
 */

import UIKit
import SnapKit

private let reuse = "VCReuse"

private let cardToScreenMargin: CGFloat = 32 // const. from Prox code.
private let interCardSpacing: CGFloat = 16

// note: can override UICollectionViewController
class ViewController: UIViewController {

    fileprivate lazy var itemSize: CGSize = {
        return CGSize(width: self.view.bounds.width - (2 * cardToScreenMargin) , height: self.view.bounds.height * (3 / 4))
    }()

    fileprivate lazy var pageWidth: CGFloat = {
        return self.itemSize.width + interCardSpacing
    }()

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = CGFloat.greatestFiniteMagnitude
        layout.minimumLineSpacing = interCardSpacing
//        layout.itemSize = self.itemSize
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        v.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuse)
        v.delegate = self
        v.dataSource = self
        v.showsHorizontalScrollIndicator = false
        v.backgroundColor = .green
        v.decelerationRate = UIScrollViewDecelerationRateFast
        v.contentInset = UIEdgeInsets(top: 0, left: cardToScreenMargin, bottom: 0, right: cardToScreenMargin)
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in [collectionView] { view.addSubview(subview) }

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuse, for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .red

        let numberLabel = UILabel()
        numberLabel.text = "\(indexPath.item)"
        numberLabel.textAlignment = .center
        cell.contentView.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in make.edges.equalToSuperview() }
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
}

// todo: explain that this actually feels good after testing so we don't need a different value.
private let neededVelocity: CGFloat = 0

extension ViewController: UIScrollViewDelegate {

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // via http://stackoverflow.com/a/35236159/

        var page = (scrollView.contentOffset.x + scrollView.contentInset.left) / pageWidth

        if (velocity.x > neededVelocity) { page.round(.up) }
        else if (velocity.x < -neededVelocity) { page.round(.down) }
        else { page.round(.toNearestOrAwayFromZero) }
        page = max(page, 0);

        let newOffset: CGFloat = page * pageWidth - scrollView.contentInset.left
        targetContentOffset.pointee.x = newOffset
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemSize.width, height: 1000)
    }
}
