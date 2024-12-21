 defmodule AlgoraEvent.Router do
   use Commanded.Commands.Router

   alias AlgoraEvent.Company

   identify Company, by: :uid

   dispatch [
     Company.Commands.Create,
     Company.Commands.Visit,
   ], to: Company
 end
