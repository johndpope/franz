//
//  ProduceAPI.swift
//  Franz
//
//  Created by Kellan Cummings on 1/17/16.
//  Copyright © 2016 Kellan Cummings. All rights reserved.
//

import Foundation

struct ProduceRequest: KafkaRequest {
	static let apiVersion: ApiVersion = 0
	
	typealias Response = ProduceResponse
	
	static let apiKey: ApiKey = .produceRequest 
	
	let values: [KafkaType]
    init(values: [String:[Int32:MessageSet]]) {

        var kafkaTopicalMessageSets = [KafkaTopicalMessageSet]()

        for (topic, partitions) in values {
            var kafkaPartitionedMessageSets = [KafkaPartitionedMessageSet]()
            for (partition, messageSet) in partitions {
                let kafkaPartitionedMessageSet = KafkaPartitionedMessageSet(
                    value: messageSet,
                    partition: partition
                )
                
                kafkaPartitionedMessageSets.append(kafkaPartitionedMessageSet)
            }
           
            kafkaTopicalMessageSets.append(
                KafkaTopicalMessageSet(
                    values: kafkaPartitionedMessageSets,
                    topic: topic
                )
            )
        }
        
        self.values = [ProduceRequestMessage(values: kafkaTopicalMessageSets)]
    }
}

struct ProduceRequestMessage: KafkaType {

    var values: [KafkaTopicalMessageSet]
    var requestAcks: Int16
    var timeout: Int32
    
    init(
        values: [KafkaTopicalMessageSet],
        timeout: Int32 = Int32(0x05DC)
    ) {
        self.values = values
        self.requestAcks = RequestAcknowledgement.noResponse.value
        self.timeout = timeout
    }

    init(data: inout Data) {
        values = [KafkaTopicalMessageSet](data: &data)
        requestAcks = Int16(data: &data)
        timeout = Int32(data: &data)
    }

    var dataLength: Int {
        return requestAcks.dataLength + timeout.dataLength + values.dataLength
    }
    
    var data: Data {
        var data = Data(capacity: dataLength)

        data.append(requestAcks.data)
        data.append(timeout.data)
        data.append(values.data)
        
        return data
    }
}

struct ProduceResponse: KafkaResponse {
	var data: Data {
		return values.data
	}
	
	var dataLength: Int {
		return values.dataLength
	}
	
    var values: [TopicalResponse]
    
    init(data: inout Data) {
        values = [TopicalResponse](data: &data)
    }
}

struct TopicalResponse: KafkaType {
    
	var topicName: TopicName
    let partitions: [PartitionedResponse]
    
    init(data: inout Data) {
        topicName = TopicName(data: &data)
        partitions = [PartitionedResponse](data: &data)
    }
    
    var dataLength: Int {
        return topicName.dataLength + partitions.dataLength
    }
    
    var data: Data {
        return Data()
    }
}

struct PartitionedResponse: KafkaType {
    private var _partition: Int32
    private var _errorCode: Int16
    private var _offset: Int64

    init(data: inout Data) {
        _partition = Int32(data: &data)
        _errorCode = Int16(data: &data)
        _offset = Int64(data: &data)
    }

    var partition: Int32 {
        return _partition
    }
    
    var offset: Int64 {
        return _offset
    }

    var error: KafkaErrorCode? {
        return KafkaErrorCode(rawValue: _errorCode)
    }
    
    var dataLength: Int {
        return _partition.dataLength + _errorCode.dataLength + _offset.dataLength
    }

    var data: Data {
        return Data()
    }
}

struct KafkaTopicalMessageSet: KafkaType {
    var values: [KafkaPartitionedMessageSet]
    var topic: String
    
    init(values: [KafkaPartitionedMessageSet], topic: String) {
        self.values = values
        self.topic = topic
    }
    
    init(data: inout Data) {
        values = [KafkaPartitionedMessageSet](data: &data)
        topic = String(data: &data)
    }
    
    var dataLength: Int {
        return topic.dataLength + values.dataLength
    }
    
    var data: Data {
        var data = Data(capacity: dataLength)
        
        data.append(topic.data)
        data.append(values.data)
        
        return data
    }
}


struct KafkaPartitionedMessageSet: KafkaType {
    var value: MessageSet
    var partition: Int32
    
    init(value: MessageSet, partition: Int32) {
        self.value = value
        self.partition = partition
    }
    
    init(data: inout Data) {
        value = MessageSet(data: &data)
        partition = Int32(data: &data)
    }
	
	var messageSetSize: Int32 {
		return Int32(value.dataLength)
	}

    var dataLength: Int {
        return partition.dataLength + messageSetSize.dataLength + value.dataLength
	}
    
    var data: Data {
        var data = Data(capacity: dataLength)
        
        data.append(partition.data)
		data.append(messageSetSize.data)
        data.append(value.data)
        
        return data
    }
}
