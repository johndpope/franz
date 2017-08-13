//
//  OffsetFetchAPI.swift
//  Pods
//
//  Created by Kellan Cummings on 1/31/16.
//
//

import Foundation


class OffsetFetchRequest: KafkaRequest {
    convenience init(
        consumerGroupId: String,
        topics: [String: [Int32]]
    ) {
        self.init(
            value: OffsetFetchRequestMessage(
                consumerGroup: consumerGroupId,
                topics: topics
            )
        )
    }
    
    init(value: OffsetFetchRequestMessage) {
        super.init(apiKey: ApiKey.offsetFetchRequest, value: value)
    }
}


class OffsetFetchRequestMessage: KafkaClass {
    
    private var _consumerGroup: KafkaString
    private var _topics: KafkaArray<OffsetFetchTopic>
    
    init(
        consumerGroup: String,
        topics: [String:[Int32]]
        ) {
            var values = [OffsetFetchTopic]()
            for (key, value) in topics {
                let offsetCommitTopic = OffsetFetchTopic(topic: key, partitions: value)
                values.append(offsetCommitTopic)
            }
            _consumerGroup = KafkaString(value: consumerGroup)
            _topics = KafkaArray(values: values)
    }
    
    required init(bytes: inout [UInt8]) {
        _consumerGroup = KafkaString(bytes: &bytes)
        _topics = KafkaArray(bytes: &bytes)
    }
    
    lazy var length: Int = {
        return self._consumerGroup.length +
            self._topics.length
    }()
    
    lazy var data: Data = {
        var data = Data(capacity: self.length)
        data.append(self._consumerGroup.data)
        data.append(self._topics.data)
        return data
    }()
    
    lazy var description: String = {
        return "OFFSET COMMIT REQUEST:\n" +
            "\tCONSUMER GROUP: \(self._consumerGroup.value ?? "nil")" +
            "\tTOPICS:\n" +
            self._topics.description
    }()
}

class OffsetFetchTopic: KafkaClass {
    
    private var _topicName: KafkaString
    private var _partitions: KafkaArray<KafkaInt32>
    
    init(
        topic: String,
        partitions: [Int32]
        ) {
            _topicName = KafkaString(value: topic)
            var values = [KafkaInt32]()
            
            for partition in partitions {
                values.append(KafkaInt32(value: partition))
            }
            
            _partitions = KafkaArray(values: values)
    }
    
    required init(bytes: inout [UInt8]) {
        _topicName = KafkaString(bytes: &bytes)
        _partitions = KafkaArray(bytes: &bytes)
    }
    
    lazy var length: Int = {
        return self._topicName.length +
            self._partitions.length
    }()
    
    lazy var data: Data = {
        var data = Data(capacity: self.length)
        data.append(self._topicName.data)
        data.append(self._partitions.data)
        return data
    }()
    
    lazy var description: String = {
        return "\tTOPIC: \(self._topicName.value ?? "nil")" +
            "\tPARTITIONS:\n" +
            self._partitions.description
    }()
}


class OffsetFetchResponse: KafkaResponse {
    
    private var _topics: KafkaArray<OffsetFetchTopicResponse>
    
    required init(bytes: inout [UInt8]) {
        _topics = KafkaArray(bytes: &bytes)
    }
    
    var topics: [OffsetFetchTopicResponse] {
        return _topics.values
    }
    
    lazy var length: Int = {
        return self._topics.length
    }()
    
    lazy var data: Data = {
        var data = Data(capacity: self.length)
        data.append(self._topics.data)
        return data
    }()
    
    var description: String {
        return "OFFSET FETCH RESPONSE:\n" +
            "\tTOPICS:\n" +
            self._topics.description
    }
}


class OffsetFetchTopicResponse: KafkaClass {
    private var _topicName: KafkaString
    private var _partitions: KafkaArray<OffsetFetchPartitionOffset>
    
    var topic: String {
        return _topicName.value ?? String()
    }
    
    var partitions: [OffsetFetchPartitionOffset] {
        return _partitions.values
    }
    
    required init(bytes: inout [UInt8]) {
        _topicName = KafkaString(bytes: &bytes)
        _partitions = KafkaArray(bytes: &bytes)
    }
    
    lazy var length: Int = {
        return self._topicName.length + self._partitions.length
    }()
    
    lazy var data: Data = {
        var data = Data(capacity: self.length)
        data.append(self._topicName.data)
        data.append(self._partitions.data)
        return data
    }()
    
    lazy var description: String = {
        return "\t\tNAME: \(self.topic)\n" +
            "\t\tPARTITIONS:\n" +
            self._partitions.description
    }()
}

typealias Offset = Int64

class OffsetFetchPartitionOffset: KafkaClass {
    private var _partition: KafkaInt32
    private var _offset: KafkaInt64
    private var _metadata: KafkaString
    private var _errorCode: KafkaInt16
    
    var error: KafkaErrorCode? {
        if _offset.value == -1 {
            return KafkaErrorCode.noError
        } else {
            return KafkaErrorCode(rawValue: _errorCode.value)
        }
    }
    
    var partition: Int32 {
        return _partition.value
    }
    
    var metadata: String {
        return _metadata.value ?? String()
    }
    
    var offset: Offset {
        return _offset.value == -1 ? 0 : _offset.value
    }
    
    required init(bytes: inout [UInt8]) {
        _partition = KafkaInt32(bytes: &bytes)
        _offset = KafkaInt64(bytes: &bytes)
        _metadata = KafkaString(bytes: &bytes)
        _errorCode = KafkaInt16(bytes: &bytes)
    }
    
    lazy var length: Int = {
        return self._partition.length +
            self._offset.length +
            self._metadata.length +
            self._errorCode.length
    }()
    
    lazy var data: Data = {
        var data = Data(capacity: self.length)
        data.append(self._partition.data)
        data.append(self._offset.data)
        data.append(self._metadata.data)
        data.append(self._errorCode.data)
        return data
    }()
    
    lazy var description: String = {
        return "\t\t\tPARTITION: \(self.partition)\n" +
            "\t\t\tOFFSET: \(self.offset)\n" +
            "\t\t\tMETADATA: \(self.metadata)\n" +
            "\t\t\tERROR: \(self.error?.description ?? String())"
    }()
}
