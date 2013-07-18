require "aws-sdk"
class S3
	include Singleton

	def initialize
		@s3 = AWS::S3.new(
 			:access_key_id => 'AKIAIUZBWCAVDL22JHPQ',
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