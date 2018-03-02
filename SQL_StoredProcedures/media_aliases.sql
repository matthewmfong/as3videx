CREATE PROCEDURE `media_aliases` ()
BEGIN

SELECT * FROM media_aliases

INNER JOIN media
ON media.id = media_aliases.media_id;

END
