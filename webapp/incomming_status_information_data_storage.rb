class IncommingStatusInformationData
  attr_accessor :bucket
  
  def initialize
    @bucket = {}
  end
  
  def create_iteration_temp_storage(user_id, conversation)
    self.bucket[user_id] = conversation 
  end

  def delete_iteration_temp_storage(user_id)
    self.bucket.delete(user_id)
  end
end

