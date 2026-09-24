def solar($alt; $az): {solar: {altitude: $alt, azimuth: $az}};
.categories |= map(
  .subcategories |= (
    if . == null then .
    else
      map(if .id == $gg then .combineVariants = true else . end)
    end

  )
)
| .assets |= map(
    if   .shotID == "GG_A_SUNSET"  then .variant = solar(5;   160)
    elif .shotID == "GG_A_DAY"     then .variant = solar(35;  180)
    elif .shotID == "GG_A_EVENING" then .variant = solar(5;   180)
    elif .shotID == "GG_A_NIGHT"   then .variant = solar(-35; 140)
    else . end
  )
