//
//  Issue15ReproTests.swift
//  ehviewer appleUITests
//
//  临时复现测试 — 不进入发布分支。
//  issue #15: 首页滚到底、底部加载圈出现后稳定闪退。
//

import XCTest

final class Issue15ReproTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeScrollToBottom() throws {
        let app = XCUIApplication()
        // 跳过站点选择与登录；18+ 警告仍需点一下（它的存储是 Bool 强转，参数域覆盖不了）
        app.launchArguments = [
            "-has_selected_site", "YES",
            "-skip_sign_in", "YES",
            "-enable_secure", "NO",
        ]
        app.launch()

        let accept = app.buttons["我已满 18 岁，继续"]
        if accept.waitForExistence(timeout: 20) {
            accept.tap()
        }

        let list = app.collectionViews.firstMatch
        guard list.waitForExistence(timeout: 30) else {
            add(XCTAttachment(screenshot: app.screenshot()))
            XCTFail("首页列表没有出现。UI:\n\(app.debugDescription)")
            return
        }

        guard app.cells.firstMatch.waitForExistence(timeout: 90) else {
            add(XCTAttachment(screenshot: app.screenshot()))
            XCTFail("首页列表一直为空（网络或站点不可达）。UI:\n\(app.debugDescription)")
            return
        }

        // 一直往上滑，滑到底部触发 loadMore
        for i in 0..<45 {
            guard app.state == .runningForeground else {
                add(XCTAttachment(screenshot: app.screenshot()))
                XCTFail("第 \(i) 次上滑前 App 已不在前台，state=\(app.state.rawValue)")
                return
            }
            list.swipeUp(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.3)
        }

        Thread.sleep(forTimeInterval: 5)
        XCTAssertEqual(app.state, .runningForeground, "滚到底后 App 崩溃")
    }
}
