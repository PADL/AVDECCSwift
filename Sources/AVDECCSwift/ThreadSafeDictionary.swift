///
/// MIT License
///
/// Copyright (c) 2020 Shashank
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///

import Dispatch

class ThreadSafeDictionary<V: Hashable, T>: Collection {
    private var dictionary: [V: T]
    private let concurrentQueue = DispatchQueue(
        label: "Dictionary Barrier Queue",
        attributes: .concurrent
    )
    var startIndex: Dictionary<V, T>.Index {
        concurrentQueue.sync {
            self.dictionary.startIndex
        }
    }

    var endIndex: Dictionary<V, T>.Index {
        concurrentQueue.sync {
            self.dictionary.endIndex
        }
    }

    init(dict: [V: T] = [V: T]()) {
        dictionary = dict
    }

    // this is because it is an apple protocol method
    // swiftlint:disable identifier_name
    func index(after i: Dictionary<V, T>.Index) -> Dictionary<V, T>.Index {
        concurrentQueue.sync {
            self.dictionary.index(after: i)
        }
    }

    // swiftlint:enable identifier_name

    subscript(key: V) -> T? {
        set(newValue) {
            concurrentQueue.async(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
        get {
            concurrentQueue.sync {
                self.dictionary[key]
            }
        }
    }

    // has implicity get
    subscript(index: Dictionary<V, T>.Index) -> Dictionary<V, T>.Element {
        concurrentQueue.sync {
            self.dictionary[index]
        }
    }

    func removeValue(forKey key: V) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.dictionary.removeValue(forKey: key)
        }
    }

    func removeAll() {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.dictionary.removeAll()
        }
    }
}
