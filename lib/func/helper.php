<?php
class Helper
{

  public function addHouse($title, $description, $category, $ownerId, $location, $requirements, $amount, $userType, $images, $rooms, $bathrooms, $userName, $community, $colorIndex, $taggedUser, $isHouse, $plot, $city, $cautionFee, $legalFee, $agentFee, $isVideo, $propertyOwnerData)
  {
    global $pdo;
    $city = $_POST['hCity'];
    $cautionFee = $_POST['cautionFee'];
    $legalFee = $_POST['legalFee'];
    $agentFee = $_POST['agentFee'];
    $query = $pdo->prepare('INSERT INTO houses (title,houseDesc,category,ownerId,hLocation,community,requirements,amount,userType,images,rooms,bathrooms,userName,color_code,tagged_userId,is_house,property_plot,hCity,cautionFee,legalFee,agentFee,isVideo,propertyOwnerData) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
    $exec = $query->execute([$title, $description, $category, $ownerId, $location, $community, $requirements, $amount, $userType, $images, $rooms, $bathrooms, $userName, $colorIndex, $taggedUser, $isHouse, $plot, $city, $cautionFee, $legalFee, $agentFee, $isVideo, $propertyOwnerData]);
    return $exec;
  }
  public function addComment($propertyId, $commenterId, $comment, $commenterName, $commenterImage)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO comment_tbl (propertyId,commenterId,comment,commenterName,commenterImage)VALUES(?,?,?,?,?)');
    $exec = $query->execute([$propertyId, $commenterId, $comment, $commenterName, $commenterImage]);
    return $exec;
  }
  public function productUpload(string $name, string $desc, $itemLocation, $amount, $itemOwnerData, $category, $state, $images, $ownerId)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO market_place (item_name,item_desc,item_location,amount,item_owner_data,item_category,pState,item_images,ownerId) VALUES (?,?,?,?,?,?,?,?,?)');
    $exec = $query->execute([$name, $desc, $itemLocation, $amount, $itemOwnerData, $category, $state, $images, $ownerId]);
    return $exec;
  }
  public function addPaymentDetails($agentId, $amount, $customerId, $paymentRef)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO payment_tbl (agentId,amount,customerId,payment_ref) VALUES(?,?,?,?)');
    $exec = $query->execute([$agentId, $amount, $customerId, $paymentRef]);
    return $exec;
  }
  public function addOrderDeal($paymentRef, $amount, $agentId, $customerId, $inspectionDate, $inspectionTime, $customerName, $propertyId, $propertyTitle)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO deals_tbl (payment_reference,amount,agent_id,customer_id,inspection_date,inspection_time,customer_name,property_id,property_title) VALUES (?,?,?,?,?,?,?,?,?)');
    $exec = $query->execute([$paymentRef, $amount, $agentId, $customerId, $inspectionDate, $inspectionTime, $customerName, $propertyId, $propertyTitle]);
    return $exec;
  }
  public function getStates()
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM state_tbl');
    $query->execute([]);
    return $query->fetchAll();
  }
  /**
   * Fetch properties for the feed by is_house/propertyType, excluding:
   *  - houses that are under_review/removed (houses.status != 'active')
   *  - agents who are suspended/under review (users.account_status != 'active')
   *  - anything the current user has personally hidden (e.g. by reporting it)
   *
   * @param string      $propertyType Value to match against houses.propertyType
   * @param int         $limit        Max rows to return
   * @param string|null $userId       Current logged-in user's UID (matches houses.ownerId
   *                                  format). Pass null for a public/logged-out feed.
   */
  public function getAllProperties($propertyType, $limit, $userId = null)
  {
    global $pdo;

    $limit   = (int) $limit; // sanitize before string-interpolating into LIMIT
    $isHouse = 1;

    $sql = "
        SELECT h.*
        FROM houses h
        INNER JOIN users a ON a.uniqueId = h.ownerId
        WHERE h.is_house = ?
          AND h.propertyType = ?
          AND h.status = 'active'
          AND a.account_status = 'active'
    ";
    // ^ Adjust a.uniqueId once you confirm your users table's real UID column.

    $params = [$isHouse, $propertyType];

    if ($userId !== null) {
      $sql .= "
          AND NOT EXISTS (
                SELECT 1 FROM hidden_feed_items hf
                WHERE hf.user_id = ?
                  AND hf.target_type = 'property'
                  AND hf.target_id = h.id
          )
          AND NOT EXISTS (
                SELECT 1 FROM hidden_feed_items hf2
                WHERE hf2.user_id = ?
                  AND hf2.target_type = 'agent'
                  AND hf2.target_id = h.ownerId
          )
        ";
      $params[] = $userId;
      $params[] = $userId;
    }

    $sql .= " ORDER BY h.dateCreated DESC LIMIT $limit";

    $query = $pdo->prepare($sql);
    $query->execute($params);
    return $query->fetchAll();
  }



  function getProducts($limit, $category)
  {
    global $pdo;
    if ($category != 'all') {
      $query = $pdo->prepare("SELECT * FROM market_place WHERE item_category=? ORDER BY createdAt DESC LIMIT $limit");
      $query->execute([$category]);
      return $query->fetchAll();
    }
    $query = $pdo->prepare("SELECT * FROM market_place ORDER BY createdAt DESC LIMIT $limit");
    $query->execute([]);
    return $query->fetchAll();
  }
  function getRelatedProducts($limit, $category, $itemId)
  {
    global $pdo;
    $sql = "SELECT *
        FROM market_place
        WHERE item_category = :item_category
          AND id != :id
        ORDER BY RAND()
        LIMIT :limit";
    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':item_category', $category, PDO::PARAM_STR);
    $stmt->bindValue(':id', $itemId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT); // number of related products to show

    $stmt->execute();
    $relatedProducts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    return $relatedProducts;
  }
  public function getPropertyById($propertyId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM houses WHERE id=? LIMIT 1');
    $query->execute([$propertyId]);
    return $query->fetch(PDO::FETCH_ASSOC);
  }
  public function getPropertyVideosOnly($limit)
  {
    global $pdo;
    $isVideo = 1;
    $query = $pdo->prepare("SELECT * FROM houses WHERE isVideo=? ORDER BY dateCreated DESC LIMIT $limit");
    $query->execute([$isVideo]);
    return $query->fetchAll();
  }
  public function getAgentDeals($agentId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM deals_tbl WHERE agent_id =? ORDER BY dateCreated DESC');
    $exec = $query->execute([$agentId]);
    return $query->fetchAll();
  }
  public function getCustomerDeals($customerId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM deals_tbl WHERE customer_id =? ORDER BY dateCreated DESC');
    $exec = $query->execute([$customerId]);
    return $query->fetchAll();
  }
  public function getAgentProperties($agentId, $limit)
  {
    global $pdo;
    $isHouse = 1;
    $query = $pdo->prepare("SELECT * FROM houses WHERE ownerId=? AND is_house=? ORDER BY dateCreated DESC LIMIT $limit");
    $query->execute([$agentId, $isHouse]);
    return $query->fetchAll();
  }
  function addBank($userId, $bankName, $accountName, $accountNumber)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO bank_details (ownerId,bankName,accountName,accountNumber) VALUES (?,?,?,?)');
    $exec = $query->execute([$userId, $bankName, $accountName, $accountNumber]);
    return $exec;
  }
  function updateDefualtBank($ownerId, $id)
  {
    global $pdo;
    $defualtBank = 1;
    $query = $pdo->prepare('UPDATE bank_details SET defaultBank=? WHERE ownerId=? AND id=? LIMIT 1');
    $exec = $query->execute([$defualtBank, $ownerId, $id]);
    return $exec;
  }
  function rescheduleDeal($dealId, $date, $time)
  {
    global $pdo;
    $query = $pdo->prepare('UPDATE deals_tbl SET inspection_date=?, inspection_time=? WHERE id=?');
    return $query->execute([$date, $time, $dealId]);
  }
  function updateDealStatus($newStatus, $dealId)
  {
    global $pdo;
    $query = $pdo->prepare('UPDATE deals_tbl SET dealStatus =? WHERE id=?');
    $exec = $query->execute([$newStatus, $dealId]);
    return $exec;
  }
  function deleteProperty($propertyId, $ownerId)
  {
    global $pdo;
    $query = $pdo->prepare('DELETE FROM houses WHERE id=? AND ownerId=?');
    $exec = $query->execute([$propertyId, $ownerId]);
    return $exec;
  }
  function unsetDefualtBank($ownerId)
  {
    global $pdo;
    $defualtBank = 0;
    $previouslySetDefulatBank = 1;
    $query = $pdo->prepare('UPDATE bank_details SET defaultBank=? WHERE ownerId=? AND defaultBank=?');
    $exec = $query->execute([$defualtBank, $ownerId, $previouslySetDefulatBank]);
    return $exec;
  }
  function sendReport($propertyId, $reporterId, $propertyOwnerId, $report)
  {
    global $pdo;
    $query = $pdo->prepare('INSERT INTO reports (reporterId,propertyId,report,propertyOwnerId) VALUES (?,?,?,?)');
    $exec = $query->execute([$reporterId, $propertyId, $report, $propertyOwnerId]);
    return $exec;
  }
  public function checkUserExist(string $email): bool
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM users WHERE email =?');
    $query->execute([$email]);
    $user = $query->fetch();
    if ($user) {
      return true;
    } else {
      return false;
    }
  }
  public function createUserAccount(string $uniqId, string $firstName, string $lastName, string $email, string $password, string $phone, string $city, string $userType, string $leadUid, string $address, string $notificationToken, string $profileImage, string $state)
  {
    global $pdo;
    $encodedPasssword = password_hash($password, PASSWORD_DEFAULT);
    $query = $pdo->prepare('INSERT INTO users (uniqueId,firstname,lastname,email,profileImage,userType,uAddress,uState,city,leadUid,phone,notification_token,user_pwd) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)');
    $exec = $query->execute([$uniqId, $firstName, $lastName, $email, $profileImage, $userType, $address, $state, $city, $leadUid, $phone, $notificationToken, $encodedPasssword]);
    if ($exec) {
      return true;
    } else {
      return false;
    }
  }
  public function loginUser(string $email, string $password, $notificationToken)
  {
    global $pdo;
    $query = $pdo->prepare("SELECT * FROM users WHERE email=?");
    $query->execute([$email]);
    $user = $query->fetch();
    if ($user) {
      if (password_verify($password, $user['user_pwd'])) {
        $updateQuery = $pdo->prepare("UPDATE users SET notification_token=? WHERE email=?");
        $updateQuery->execute([$notificationToken, $email]);
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
  public function getUser(string $email)
  {
    global $pdo;
    $query = $pdo->prepare("SELECT * FROM users WHERE email=?");
    $query->execute([$email]);
    $user = $query->fetch();
    return $user;
  }
  public function getUserById(string $userId)
  {
    global $pdo;
    $query = $pdo->prepare("SELECT * FROM users WHERE uniqueId=?");
    $query->execute([$userId]);
    $user = $query->fetch();
    return $user;
  }
  function getBalance($userId)
  {
    global $pdo;
    $query = $pdo->prepare("SELECT w_balance FROM balances WHERE ownerId=?");
    $query->execute([$userId]);
    $balance = $query->fetch();
    return $balance['w_balance'];
  }
  function updateBalance($userId, $amount)
  {
    global $pdo;
    $query = $pdo->prepare("UPDATE balances SET w_balance = w_balance +$amount WHERE ownerId=?");
    $exec = $query->execute([$userId]);
    return $exec;
  }
  function setBalance($userId, $amount)
  {
    global $pdo;
    $query = $pdo->prepare("INSERT INTO balances (ownerId,w_balance) VALUES (?,?)");
    $exec = $query->execute([$userId, $amount]);
    return $exec;
  }
  function getWalletBalance($ownerId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM balances WHERE ownerId=?');
    $exec = $query->execute([$ownerId]);
    return $query->fetch(PDO::FETCH_ASSOC);
  }
  function getCharges()
  {
    global $pdo;
    $id = 1;
    $query = $pdo->prepare('SELECT * FROM charges WHERE id=?');
    $exec = $query->execute([$id]);
    return $query->fetch(PDO::FETCH_ASSOC);
  }
  function checkWalletExists($userId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM balances WHERE ownerId=?');
    $exec = $query->execute([$userId]);
    $alreadyExist = 0;
    if ($query->rowCount() > 0) {
      $alreadyExist = 1;
    }
    return $alreadyExist;
  }
  function getUserBanks($userId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM bank_details WHERE ownerId=? ORDER BY  dateCreated DESC');
    $exec = $query->execute([$userId]);
    return $query->fetchAll();
  }
  function checkEmailExist($email)
  {
    global $pdo;
    $alreadyExist = 0;
    $query = $pdo->prepare('SELECT * FROM users WHERE email=?');
    $exec = $query->execute([$email]);
    if ($query->rowCount() > 0) {
      $alreadyExist = 1;
    } else {
      $alreadyExist = 0;
    }
    return $alreadyExist;
  }
  // function addUser($firstname, $lastname, $email, $profileImage, $phone, $userType, $address, $state, $city)
  // {
  //   global $pdo;
  //   $query = $pdo->prepare('INSERT INTO users (uniqId,fullName,phone,uAddress,schName,uEmail,department,schAddress,userType,uState,uCity,uPwd) values (?,?,?,?,?,?,?,?,?,?,?,?)');
  //   $exec = $query->execute([$uniqId, $fullName, $phone, $address, $schName, $email, $department, $schAddress, $userType, $state, $city, $uPwd]);
  //   return $exec;
  // }
  function checkBankExist($userId, $bankName, $accountName, $accountNumber)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM bank_details WHERE ownerId=? AND bankName=? AND accountName=? AND accountNumber=?');
    $exec = $query->execute([$userId, $bankName, $accountName, $accountNumber]);
    $alreadyExist = false;
    if ($query->rowCount() > 0) {
      $alreadyExist = true;
    }
    return $alreadyExist;
  }
  public function getMixedProperties($limit)
  {
    global $pdo;
    $isHouse = 1;
    $query = $pdo->prepare("SELECT * FROM houses ORDER BY dateCreated DESC LIMIT $limit");
    $query->execute([]);
    return $query->fetchAll();
  }
  public function getProperties($propertyType, $limit)
  {
    global $pdo;
    $query = $pdo->prepare("SELECT * FROM houses WHERE category=? ORDER BY dateCreated DESC LIMIT $limit");
    $query->execute([$propertyType]);
    return $query->fetchAll();
  }

  /**
   * Fetch properties for the feed, excluding:
   *  - houses that are under_review/removed (houses.status != 'active')
   *  - agents who are suspended/under review (users.account_status != 'active')
   *  - anything the current user has personally hidden (e.g. by reporting it)
   *
   * @param string      $propertyType Category to filter by
   * @param int         $limit        Max rows to return
   * @param string|null $userId       Current logged-in user's UID (matches houses.ownerId
   *                                  format). Pass null for a public/logged-out feed.
   */
  // public function getProperties($propertyType, $limit, $userId = null)
  // {
  //   global $pdo;

  //   $limit = (int) $limit; // sanitize before string-interpolating into LIMIT

  //   $sql = "
  //       SELECT h.*
  //       FROM houses h
  //       INNER JOIN users a ON a.uniqueId = h.ownerId
  //       WHERE h.category = ?
  //         AND h.status = 'active'
  //         AND a.account_status = 'active'
  //   ";
  //   // ^ Adjust a.uniqueId to whatever your users table's real UID column
  //   //   is called once confirmed — see note in schema_reports.sql.

  //   $params = [$propertyType];

  //   if ($userId !== null) {
  //     $sql .= "
  //         AND NOT EXISTS (
  //               SELECT 1 FROM hidden_feed_items hf
  //               WHERE hf.user_id = ?
  //                 AND hf.target_type = 'property'
  //                 AND hf.target_id = h.id
  //         )
  //         AND NOT EXISTS (
  //               SELECT 1 FROM hidden_feed_items hf2
  //               WHERE hf2.user_id = ?
  //                 AND hf2.target_type = 'agent'
  //                 AND hf2.target_id = h.ownerId
  //         )
  //       ";
  //     $params[] = $userId;
  //     $params[] = $userId;
  //   }

  //   $sql .= " ORDER BY h.dateCreated DESC LIMIT $limit";

  //   $query = $pdo->prepare($sql);
  //   $query->execute($params);
  //   return $query->fetchAll();
  // }
  public function getComments($propertyId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM comment_tbl WHERE propertyId=?');
    $query->execute([$propertyId]);
    return $query->fetchAll();
  }
  public function getReactions($propertyId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM thumps_up_tbl WHERE propertyId=?');
    $query->execute([$propertyId]);
    return $query->fetchAll();
  }
  public function searchProperty($keyword)

  {
    $keyword = '%' . $keyword . '%';
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM houses WHERE category LIKE ? OR community LIKE ? OR userName LIKE ? OR hLocation LIKE ? OR houseDesc LIKE ? LIMIT 50');
    $query->execute([$keyword, $keyword, $keyword, $keyword, $keyword]);
    return $query->fetchAll();
  }

  public function searchProducts($query)

  {
    global $pdo;
    $newQuery = '%' . $query . '%';

    $stmt = $pdo->prepare(
      'SELECT * FROM market_place 
         WHERE item_name LIKE ? 
            OR item_category LIKE ? 
            OR item_desc LIKE ? 
         LIMIT 50'
    );
    $stmt->execute([$newQuery, $newQuery, $newQuery]);
    return $stmt->fetchAll();
  }
  /**
   * Search-sheet filter: every field is optional and only narrows the
   * result when present. Sent by the app as:
   *   keyword, categories ("Land|Hall"), state, city, community,
   *   minPrice, maxPrice, minRooms, minBathrooms,
   *   media ("photos" | "videos"), sort ("newest" | "priceLowHigh" | "priceHighLow")
   */
  public function advancedFilterProperties($input)
  {
    global $pdo;
    $where = ["status = 'active'"];
    $params = [];

    if (!empty($input['keyword'])) {
      $kw = '%' . $input['keyword'] . '%';
      $where[] = '(title LIKE ? OR category LIKE ? OR community LIKE ? OR userName LIKE ? OR hLocation LIKE ? OR hCity LIKE ? OR houseDesc LIKE ?)';
      array_push($params, $kw, $kw, $kw, $kw, $kw, $kw, $kw);
    }
    if (!empty($input['categories'])) {
      $categories = array_values(array_filter(explode('|', $input['categories'])));
      if ($categories) {
        $where[] = 'category IN (' . implode(',', array_fill(0, count($categories), '?')) . ')';
        $params = array_merge($params, $categories);
      }
    }
    if (!empty($input['state'])) {
      $where[] = 'hLocation = ?';
      $params[] = $input['state'];
    }
    if (!empty($input['city'])) {
      $where[] = 'hCity = ?';
      $params[] = $input['city'];
    }
    if (!empty($input['community'])) {
      $where[] = 'community LIKE ?';
      $params[] = '%' . $input['community'] . '%';
    }
    if (isset($input['minPrice']) && $input['minPrice'] !== '') {
      $where[] = 'CAST(amount AS DECIMAL(15,2)) >= ?';
      $params[] = (float) $input['minPrice'];
    }
    if (isset($input['maxPrice']) && $input['maxPrice'] !== '') {
      $where[] = 'CAST(amount AS DECIMAL(15,2)) <= ?';
      $params[] = (float) $input['maxPrice'];
    }
    if (!empty($input['minRooms'])) {
      $where[] = 'rooms >= ?';
      $params[] = (int) $input['minRooms'];
    }
    if (!empty($input['minBathrooms'])) {
      $where[] = 'bathrooms >= ?';
      $params[] = (int) $input['minBathrooms'];
    }
    if (($input['media'] ?? '') === 'videos') {
      $where[] = 'isVideo = 1';
    } else if (($input['media'] ?? '') === 'photos') {
      $where[] = 'isVideo != 1';
    }

    switch ($input['sort'] ?? 'newest') {
      case 'priceLowHigh':
        $order = 'CAST(amount AS DECIMAL(15,2)) ASC';
        break;
      case 'priceHighLow':
        $order = 'CAST(amount AS DECIMAL(15,2)) DESC';
        break;
      default:
        $order = 'dateCreated DESC';
    }

    $sql = 'SELECT * FROM houses WHERE ' . implode(' AND ', $where) . " ORDER BY $order LIMIT 100";
    $query = $pdo->prepare($sql);
    $query->execute($params);
    return $query->fetchAll();
  }

  public function filterProperty($propertyType, $state, $city, $community)
  {
    global $pdo;
    $community = '%' . $community . '%';
    $query = $pdo->prepare('SELECT * FROM houses WHERE category=? AND hLocation=? AND hCity=? AND community LIKE ? LIMIT 50');
    $query->execute([$propertyType, $state, $city, $community]);
    return $query->fetchAll();
  }
  public function reactOnProperty($propertyId, $userId, $userName, $reactionType)
  {
    global $pdo;
    $exec = false;
    $query = $pdo->prepare('SELECT * FROM thumps_up_tbl WHERE propertyId=? AND userId=? LIMIT 1');
    $query->execute([$propertyId, $userId]);
    if ($query->rowCount() > 0) {
      $result = $query->fetch(PDO::FETCH_ASSOC);
      if ($reactionType == 'thumbs up') {
        //At this point user has already reacted before so am checking if he did thumbs down before then i would unreact is thumb down and react to thumbs up
        // Else i delete the user reaction
        if ($result['thumb_down'] == 1) {
          $thumdown = 0;
          $thumbup = 1;
          $queryUpdate = $pdo->prepare('UPDATE thumps_up_tbl SET thumb_down=?,thumb_up=? WHERE propertyId=? AND userId=?');
          $exec = $queryUpdate->execute([$thumdown, $thumbup, $propertyId, $userId]);
        } else {
          $deleteQuery = $pdo->prepare('DELETE FROM thumps_up_tbl WHERE propertyId=? AND userId=?');
          $exec =  $deleteQuery->execute([$propertyId, $userId]);
        }
      } else {
        //At this point user has already reacted before so am checking if he did thumbs up before then i would unreact is thumb up and react to thumbs down
        // Else i delete the user reaction
        if ($result['thumb_up'] == 1) {
          $thumdown = 1;
          $thumbup = 0;
          $queryUpdate = $pdo->prepare('UPDATE thumps_up_tbl SET thumb_down=?,thumb_up=? WHERE propertyId=? AND userId=?');
          $exec =  $queryUpdate->execute([$thumdown, $thumbup, $propertyId, $userId]);
        } else {
          $deleteQuery = $pdo->prepare('DELETE FROM thumps_up_tbl WHERE propertyId=? AND userId=?');
          $exec =  $deleteQuery->execute([$propertyId, $userId]);
        }
      }
    } else {
      if ($reactionType == 'thumbs up') {
        $thumdown = 0;
        $thumbup = 1;
        $insertQuery = $pdo->prepare('INSERT INTO thumps_up_tbl (thumb_up,propertyId,userId,userName,thumb_down) VALUES (?,?,?,?,?)');
        $exec = $insertQuery->execute([$thumbup, $propertyId, $userId, $userName, $thumdown]);
      } else {
        $thumdown = 1;
        $thumbup = 0;
        $insertQuery = $pdo->prepare('INSERT INTO thumps_up_tbl (thumb_up,propertyId,userId,userName,thumb_down) VALUES (?,?,?,?,?)');
        $exec = $insertQuery->execute([$thumbup, $propertyId, $userId, $userName, $thumdown]);
      }
    }
    return $exec;
  }
  public function isFollowing($currentUserId, $userId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM followers_tbl WHERE follower_id=? AND userId=? ');
    $query->execute([$currentUserId, $userId]);
    return $query->rowCount();
  }
  public function addFollower($currentUserId, $userId, $isUnfollow)
  {
    global $pdo;
    if ($isUnfollow == false) {
      $query = $pdo->prepare('INSERT INTO followers_tbl (follower_id,userId)VALUES(?,?)');
      $exec = $query->execute([$currentUserId, $userId]);
    } else {
      $query = $pdo->prepare('DELETE FROM followers_tbl WHERE follower_id=? AND userId=?');
      $exec = $query->execute([$currentUserId, $userId]);
    }
    return $exec;
  }
  // public function addFollowing($currentUserId,$userId) {
  //   global $pdo;
  //   $query= $pdo->prepare('INSERT INTO following_tbl (following_id,userId)VALUES(?,?)');
  //   $exec = $query->execute([$currentUserId,$userId]);
  //   return $exec;
  // }
  public function getFollowers($userId)
  {
    global $pdo;
    $query = $pdo->prepare('SELECT * FROM followers_tbl WHERE userId=?');
    $query->execute([$userId]);
    return $query->fetchAll();
  }


  private $apiKey = 'YOUR_GEMINI_API_KEY';
  // Tried in order; on overload (503), rate limit (429), timeout or a
  // retired model (404) the next one is used. Measured 2026-10-09:
  // gemini-3.8-flash failed ~2/3 calls with 503 "high demand", while these
  // all answered 3/3 in 1-2s. Reorder/replace as Google's models change.
  private $geminiModels = [
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.6-flash',
  ];

  /**
   * AI neighbourhood summary for a listing's area, as a structured array:
   *   headline, overview, factors[{key,label,score(1-5|null),summary}],
   *   landmarks[{name,type}], good_for[], watch_out[], tips[]
   * Cached per area in area_insights (sql/area_insights.sql) so each area is
   * only generated once; returns null if the AI call fails.
   */
  public function getAreaInsights($community, $city, $state, $propertyType)
  {
    global $pdo;
    // "v2|" = schema version: bumped when the prompt's fields change (v2
    // added internet + MTN FiberX) so older cached entries regenerate.
    $areaKey = 'v2|' . strtolower(trim("$community|$city|$state"));

    // 1. Cache hit (fresh within 30 days).
    try {
      $q = $pdo->prepare("SELECT payload FROM area_insights WHERE area_key = ? AND created_at > (NOW() - INTERVAL 30 DAY) LIMIT 1");
      $q->execute([$areaKey]);
      $cached = $q->fetchColumn();
      if ($cached) {
        $decoded = json_decode($cached, true);
        if (is_array($decoded)) return $decoded;
      }
    } catch (PDOException $e) {
      // Cache table not created yet - generate without caching.
    }

    // 2. Ask Gemini for structured JSON.
    $place = implode(', ', array_filter([$community, $city, $state, 'Nigeria']));
    $prompt = <<<PROMPT
You are a careful local real estate analyst for Aboostoplus, a Nigerian property app.
Write a neighbourhood briefing for someone considering a "$propertyType" in: $place.

Rules:
- Be honest and practical. Use well-known, general knowledge about the area only.
- Do NOT invent precise statistics, prices, distances or business names you are not confident exist.
- If you lack reliable information on a point, set its score to null and say so plainly in the summary.
- Landmarks must be real, widely known places in or near the area (max 6). If unsure, return fewer.
- Keep every summary to 1-2 short sentences.
- For MTN FiberX (MTN Nigeria's fibre-to-the-home broadband): only say "available" if you are
  confident MTN FiberX serves this specific area. Use "likely" for well-developed estates/areas in
  cities where MTN FiberX operates, "unlikely" where coverage is improbable, and "unknown" otherwise.
  Never claim certainty you do not have; coverage is street-by-street.

Return ONLY JSON with this shape:
{
  "headline": "one-line takeaway about the area",
  "overview": "2-3 sentence description of the area's character",
  "factors": [
    {"key": "power", "label": "Electricity", "score": 1-5 or null, "summary": "..."},
    {"key": "internet", "label": "Internet", "score": 1-5 or null, "summary": "mobile data / 4G-5G quality and broadband options"},
    {"key": "security", "label": "Security", "score": 1-5 or null, "summary": "..."},
    {"key": "roads", "label": "Roads & access", "score": 1-5 or null, "summary": "..."},
    {"key": "water", "label": "Water supply", "score": 1-5 or null, "summary": "..."},
    {"key": "flooding", "label": "Flood safety", "score": 1-5 or null, "summary": "5 means low flood risk"},
    {"key": "transport", "label": "Transport", "score": 1-5 or null, "summary": "..."}
  ],
  "mtn_fiberx": {"status": "available|likely|unlikely|unknown", "summary": "1 sentence on MTN FiberX fibre coverage here"},
  "landmarks": [{"name": "...", "type": "school|hospital|market|mall|worship|park|bank|government|transport|other"}],
  "good_for": ["short phrase", "..."],
  "watch_out": ["short phrase", "..."],
  "tips": ["practical tip for a renter/buyer here", "..."]
}
Higher scores are always better for the resident.
PROMPT;

    $body = [
      'contents' => [['parts' => [['text' => $prompt]]]],
      'generationConfig' => [
        'temperature' => 0.3,
        'responseMimeType' => 'application/json',
      ],
    ];

    // Walk the model list until one answers, within an overall time budget
    // (the app waits up to 75s; area-insights.php allows 90s).
    $deadline = microtime(true) + 60;
    $raw = false;
    $httpCode = 0;
    foreach ($this->geminiModels as $model) {
      $remaining = (int) floor($deadline - microtime(true));
      if ($remaining < 5) break;

      $ch = curl_init("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent");
      curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => min(25, $remaining),
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'x-goog-api-key: ' . $this->apiKey],
        CURLOPT_POSTFIELDS => json_encode($body),
      ]);
      $raw = curl_exec($ch);
      $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
      $curlError = curl_error($ch);
      curl_close($ch);

      if ($raw !== false && $httpCode === 200) break;
      error_log("Area insights: $model failed ($httpCode) $curlError " . substr((string) $raw, 0, 200));
      // Anything else (e.g. 400 bad request / 403 bad key) won't be fixed
      // by another model.
      $tryNext = $raw === false || in_array($httpCode, [404, 429], true) || $httpCode >= 500;
      if (!$tryNext) break;
    }

    if ($raw === false || $httpCode !== 200) {
      return null;
    }

    $result = json_decode($raw, true);
    // Newer models can split output across several parts (some flagged as
    // thoughts) - join the visible text parts.
    $text = '';
    foreach (($result['candidates'][0]['content']['parts'] ?? []) as $part) {
      if (!empty($part['thought'])) continue;
      $text .= $part['text'] ?? '';
    }
    // Tolerate a stray ```json fence around the payload.
    $text = trim(preg_replace('/^```(?:json)?|```$/m', '', $text));
    $insights = json_decode($text, true);
    if (!is_array($insights) || empty($insights['overview'])) {
      error_log('Area insights: unparseable model output: ' . substr($text, 0, 300));
      return null;
    }

    // 3. Cache it.
    try {
      $save = $pdo->prepare("REPLACE INTO area_insights (area_key, payload, created_at) VALUES (?, ?, NOW())");
      $save->execute([$areaKey, json_encode($insights)]);
    } catch (PDOException $e) {
      // No cache table - fine.
    }

    return $insights;
  }
}
