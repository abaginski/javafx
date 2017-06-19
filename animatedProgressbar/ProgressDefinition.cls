/* rgf, 2017-06-12
   purpose: mixin class to define the attributes that a progress indicator (maybe GUI) program
            and a (process) program that wishes to signal its progress.

            The progress indicator program (e.g. a ProgressBar) is supposed to set the attribute
            <code>progressStoppedByUser</code> to <code>.true</code>, if the user wishes the
            process to stop.

            The process program (e.g. a long running XML parser) is supposted to set the attribute
            <code>processingEnded</code> to <code>.true</code>, if it finished processing.

*/

::class ProgressDefinition mixinclass object public

/* Constructor method.
   @param lowerBound  any number the progress starts with, optional (defaults to 0)
   @param uppperBound any number the progress ends with, must be larger than <code>lowerBound</code> optional (defaults to 100)
   @param currentValue any number indicating state of the progress, optional (defaults to lowerBound)
*/
::method init
  expose lowerBound upperBound currentValue progressStoppedByUser processingEnded
  use strict arg lowerBound=0, upperBound=100, currentValue=(lowerBound)

  if \datatype(lowerBound,'Number') then
     raise syntax 93.904 array ('lowerBound', lowerBound)

  if \datatype(upperBound,'Number') then
     raise syntax 93.904 array ('upperBound', upperBound)

  if \datatype(currentValue,'Number') then
     raise syntax 93.904 array ('currentValue', currentValue)

  if lowerBound>upperBound then
      raise syntax 93.908 array ('lowerBound', 'upperBound', lowerBound)

  if lowerBound>upperBound then
      raise syntax 93.900 array ('lowerBound value ('lowerBound') must not be larger than upperBound ('upperBound') value!')

  if lowerBound=upperBound then
      raise syntax 93.900 array ('lowerBound value ('lowerBound') must not be equal to upperBound ('upperBound') value!')

  progressStoppedByUser=.false
  processingEnded=.false
  self~calcCurrentPosition    -- calculate position in progress bar (between 0 and 100)


/* The lower bound number (will be regarded to be 0%). */
::attribute lowerBound get
::attribute lowerBound set
  expose lowerBound upperBound
  use strict arg newLowerBound

  if \datatype(newLowerBound,'Number') then
     raise syntax 93.904 array ('lowerBound',newLowerBound)

  if newLowerBound=upperBound then
     raise syntax 93.900 array ('lowerBound value ('newLowerBound') must not be equal to upperBound ('upperBound') value!')

  if newLowerBound>upperBound then
      raise syntax 93.900 array ('lowerBound value ('newLowerBound') must not be larger than upperBound ('upperBound') value!')

  lowerBound=newLowerBound
  self~calcCurrentPosition

/* The upperBound number (will be regarded to be 100%). */
::attribute upperBound get
::attribute upperBound set
  expose lowerBound upperBound
  use strict arg newUpperBound

  if \datatype(newUpperBound,'Number') then
     raise syntax 93.904 array ('upperBound',newUpperBound)

  if newUpperBound=lowerBound then
     raise syntax 93.900 array ('upperBound value ('newUpperBound') must not be equal to lowerBound ('lowerBound') value!')

  if newUpperBound<lowerBound then
      raise syntax 93.900 array ('upperBound value ('newUpperBound') must not be smaller than lowerBound ('lowerBound') value!')

  upperBound=newUpperBound
  self~calcCurrentPosition

/* The current value, which is equal or larger than <code>lowerBound</code> and
   smaller or equal to the <code>upperBound</code>. */
::attribute currentValue get
::attribute currentValue set
  expose currentValue
  use strict arg newCurrentValue

  if \datatype(newCurrentValue,'Number') then
     raise syntax 93.904 array ('currentValue',newCurrentValue)
  currentValue=newCurrentValue
  self~calcCurrentPosition

/* The position, a value between 0% and 100%, will be calculated by
   <code>calcCurrentPosition</code> gets set.
*/
::attribute currentPosition get
  expose currentPosition
  return currentPosition

::attribute currentPosition set
  expose currentPosition
  use strict arg newCurrentPosition

  if newCurrentPosition<0 | newCurrentPosition>100 then
     raise syntax 93.904 array ('currentValue')
  currentPosition=newCurrentPosition

::method calcCurrentPosition
  expose lowerBound upperBound currentValue currentPosition

  select
  when currentValue<=lowerBound then currentPosition=0   --   0%
  when currentValue>=upperBound then currentPosition=1   -- 100%
  when lowerBound=upperBound    then currentPosition=1   -- 100%
  otherwise
     currentPosition=(currentValue-lowerBound)/(upperBound-lowerBound)
  end

/* If <code>.true</code>, then the user indicated that s/he wishes the process
   to be stopped. */
::attribute progressStoppedByUser get
  expose progressStoppedByUser
  return progressStoppedByUser

::attribute progressStoppedByUser set
  expose progressStoppedByUser processingEnded
  use strict arg progressStoppedByUser
  processingEnded = .true

/* If <code>.true</code>, then the process indicates that it has finished. */
::attribute processingEnded

