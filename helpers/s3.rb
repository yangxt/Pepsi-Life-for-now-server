require "aws-sdk"
class S3
	include Singleton

	def initialize
		@s3 = AWS::S3.new(
 			:access_key_id => 'AKIAIHTVW7A7X4FBDBDA',
  			:secret_access_key => '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')
		@buckets = {} 
	end
	
	def bucket(name)
		bucket = @buckets[name]
		if bucket
			return bucket
		else
			bucket = @s3.buckets[name];
			if bucket
				@buckets[name] = bucket
			end
			return bucket
		end
	end

	def url(bucketName)
		"https://" + bucketName + ".s3.amazonaws.com/"
	end
end