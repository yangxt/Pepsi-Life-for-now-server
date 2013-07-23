 # -*- coding: utf-8 -*-
require ('./tests/test_tools')

TestTools.delete_all
me = TestTools.create_user_with("testuser", "testuser", "testuser", "...", "...")
user1 = TestTools.create_user_with("claude", "claude", "Claude Simons", "...", "J'adore Pepsi")
user2 = TestTools.create_user_with("marion", "marion", "Marion", "...", "Une petite bouteille de Pepsi?")
user3 = TestTools.create_user_with("jeremy", "jeremy", "Jeremy", "...", "Quel bel été")
user4 = TestTools.create_user_with("williambrasseur", "williambrasseur", "William Brasseur", "...", "")
user5 = TestTools.create_user_with("jonathan", "jonathan", "Jonathan", "...", "Twitter: @jonathan")
user6 = TestTools.create_user_with("francois", "francois", "François", "...", "C'est la fête!")

##################
#Friends
##################

TestTools.create_friendship(me, user1);
TestTools.create_friendship(me, user3);
TestTools.create_friendship(me, user5);

##################
#user1
##################
user1_post1 = TestTools.create_post_with("Recent advances will help victims of the attack who underwent amputations", "...", DateTime.new(2013,6,1,4,5,6,'+2'), user1)
user1_post2 = TestTools.create_post_with("With Greece’s economy in free-fall, many children are arriving at school hungry, underfed or malnourished.", "...", DateTime.new(2013,6,3,6,8,6,'+1'), user1)
user1_post3 = TestTools.create_post_with("After Dwight Howard signed with the Houston Rockets on Friday, Kobe Bryant issued a passive-aggressive response, posting a picture of himself and Pau Gasol on Instagram.", "...", DateTime.new(2013,6,7,11,8,6,'+1'), user1)
user1_post4 = TestTools.create_post_with("People in northern China may be dying five years sooner than expected because of diseases caused by air pollution, an unintended result of a decades-old policy providing free coal for heat, a study found.", "...", DateTime.new(2013,6,9,3,4,6,'-1'), user1)
user1_post5 = TestTools.create_post_with("Analysis of ice cores obtained from the basin of Lake Vostok, the subglacial lake that Russian scientists drilled down to in 2012, have revealed DNA from an estimated 3,507 organisms.", "...", DateTime.new(2013,6,15,17,34,6,'+1'), user1)

#likes
TestTools.create_like_on_post_with_user(user1_post1, user1)
TestTools.create_like_on_post_with_user(user1_post1, user3)
TestTools.create_like_on_post_with_user(user1_post2, user2)
TestTools.create_like_on_post_with_user(user1_post2, user3)
TestTools.create_like_on_post_with_user(user1_post2, user6)
TestTools.create_like_on_post_with_user(user1_post3, user2)
TestTools.create_like_on_post_with_user(user1_post5, user3)

#tags
TestTools.create_tag_with(user1_post1, "#war")
TestTools.create_tag_with(user1_post2, "#economy")
TestTools.create_tag_with(user1_post2, "#world")
TestTools.create_tag_with(user1_post3, "#sport")
TestTools.create_tag_with(user1_post3, "#people")
TestTools.create_tag_with(user1_post4, "#science")

##################
#user2
##################
user2_post1 = TestTools.create_post_with("Pepsi, c'est trop bon", "...", DateTime.new(2013,6,19,3,5,7,'-6'), user2)
user2_post2 = TestTools.create_post_with("Vacances en Egypte", "...", DateTime.new(2013,6,26,5,8,6,'+1'), user2)
user2_post3 = TestTools.create_post_with("The Times’s Susan Dominus talks to the organizational psychologist Adamrs, takers and succeeding in the workplace.", "...", DateTime.new(2013,6,29,6,3,6,'+3'), user2)

#likes
TestTools.create_like_on_post_with_user(user2_post1, user1)
TestTools.create_like_on_post_with_user(user2_post1, user3)
TestTools.create_like_on_post_with_user(user1_post2, user2)

#tags
TestTools.create_tag_with(user2_post1, "#pepsi")

##################
#user3
##################
user3_post1 = TestTools.create_post_with("Three women held captive in a Cleveland home for a decade issued a YouTube video Monday night in which they thanked the public for the encouragement and financial support that is allowing them to restart their lives.", "...", DateTime.new(2013,7,1,3,7,6,'+4'), user3)
user3_post2 = TestTools.create_post_with("The findings on sleep patterns and brain power come from a UK study of more than 11,000 seven-year-olds. Youngsters who had no regular bedtime or who went to bed later than 21:00 had lower scores for reading and maths.", "...", DateTime.new(2013,7,2,16,34,11,'+1'), user1)

#likes
TestTools.create_like_on_post_with_user(user3_post1, user1)
TestTools.create_like_on_post_with_user(user3_post1, user3)
TestTools.create_like_on_post_with_user(user3_post1, user2)

#tags
TestTools.create_tag_with(user3_post1, "#world")
TestTools.create_tag_with(user1_post2, "#science")


##################
#user4
##################
user4_post1 = TestTools.create_post_with("A day after the release of iOS 7 beta 3, the second version for the iPhone and the third for the iPad, the same pattern which emerged with beta 1 and 2 is continuing: thus far iOS 7 is more stable and less glitch prone on the iPhone 5 than it is on the older...", "...", DateTime.new(2013,7,3,2,1,6,'+8'), user4)

#tags
TestTools.create_tag_with(user4_post1, "#technology")

##################
#user5
##################
user5_post1 = TestTools.create_post_with("Eagle-eyed Flickr users spotted that two of Joe Belfiore's images were marked as being shot by a Nokia Lumia 1020, potentially ending months of speculation about the phone's title.", "...", DateTime.new(2013,7,5,4,1,6,'+2'), user5)
user5_post2 = TestTools.create_post_with("George Clooney isn't exactly single (yet) ... TMZ has learned he and Stacy Keibler are STILL living together -- despite rumors of a break-up -- BUT an expiration date could be fast approaching.", "...", DateTime.new(2013,7,9,6,1,6,'-1'), user5)

#likes
TestTools.create_like_on_post_with_user(user5_post1, user1)
TestTools.create_like_on_post_with_user(user5_post1, user3)
TestTools.create_like_on_post_with_user(user5_post1, user2)

#tags
TestTools.create_tag_with(user5_post1, "#technology")
TestTools.create_tag_with(user5_post2, "#people")


##################
#comments
##################

TestTools.create_comment_with(user2_post1, user1, "Bien raison", DateTime.new(2013,6,23,4,5,6,'+2'))
TestTools.create_comment_with(user3_post2, user1, "What a great study", DateTime.new(2013,7,3,6,8,6,'+1'))

TestTools.create_comment_with(user1_post1, user2, "Love this!", DateTime.new(2013,7,5,4,5,6,'+2'))
TestTools.create_comment_with(user1_post3, user2, "That's sad :(", DateTime.new(2013,6,10,6,8,6,'+1'))

TestTools.create_comment_with(user1_post2, user3, "Damn economy", DateTime.new(2013,7,5,4,5,6,'+2'))

TestTools.create_comment_with(user5_post1, user4, "Clooney's so cute", DateTime.new(2013,7,15,4,5,6,'+2'))

