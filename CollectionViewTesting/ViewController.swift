//
//  ViewController.swift
//  CollectionViewTesting
//
//  Created by Michael Comella on 3/29/17.
//  Copyright © 2017 Michael Comella. All rights reserved.
//

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
        layout.itemSize = self.itemSize
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
            make.edges.equalToSuperview()
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

// todo: explain
private let neededVelocity: CGFloat = 0

// if lib:
// - How handle non-cell views, footers & headers?
extension ViewController: UICollectionViewDelegate {

    // or maybe use `uicollectionviewlayout.targetContentOffset(forProposedContentOffset: CGPoint, withScrollingVelocity: CGPoint)`
    // http://blog.karmadust.com/centered-paging-with-preview-cells-on-uicollectionview/
    //
    // alternative solution: create a scroll view with paging enabled
    // difference: you can swipe through multiple if you swipe fast enough here (but could fix).
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
