//
//  File.swift
//  
//
//  Created by Martin Albrecht on 01.06.20.
//

final class CoreStorage {
    private let size: StorageSize
    private var storage = [Word]()

    enum StorageSize: Int {
        case k1 = 1400
        case k2 = 2000
        case k4 = 4000
        case k8 = 8000
        case k12 = 12000
        case k16 = 16000
    }
    
    init(size: StorageSize) {
        for _ in 0...(size.rawValue-1) {
            self.storage.append(0b01000000)
        }
        
        self.size = size
    }
    
    func count() -> Int {
        return storage.count
    }
    
    func get(from addr: Int, setZero: Bool = true) -> Word {
        if addr <= storage.count {
            let item = storage[addr]
            
            if setZero {
                storage[addr] &= 0b01000000
            }
            
            return item
        }
        
        return 0
    }
    
    func set(at addr: Int, with value: Word) {
        if addr <= storage.count {
            storage[addr] = value
        }
    }
    
    func setWordMark(at addr: Int) {
        if addr <= storage.count {
            storage[addr].setWordMark()
        }
    }
    
    func setCheckBit(at addr: Int) {
        if addr <= storage.count {
            storage[addr].setCheckBit()
        }
    }
    
    func storageSize() -> StorageSize {
        return size
    }
}
